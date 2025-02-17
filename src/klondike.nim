import strutils, sequtils
import std/os
import marshal
import std/options, std/strformat
import std/random
import std/enumerate
import ncurses

import constants

randomize()

const PLAYING_CARD_BACK = "🂠"

const DEBUG: bool = true
const DRAW_SIMPLE = true

proc log*(s: string) = 
  if DEBUG:
    echo s

type 
  Suit* = enum
    Hearts = "Hearts", Spades = "Spades", Diamonds = "Diamonds", Clubs = "Clubs"
  
  Face* = range[0..12]
  
  Card* = object
    suit: Suit
    face: Face
    flip: bool
  
  Color* = enum
    Red, Black


type 
  KlondikeState* = object
    playing: bool

    deck: seq[Card]    
    pile: seq[Card]

    tableauOne: seq[Card]
    tableauTwo: seq[Card]
    tableauThree: seq[Card]
    tableauFour: seq[Card]
    tableauFive: seq[Card]
    tableauSix: seq[Card]
    tableauSeven: seq[Card]

    foundationOne: seq[Card]
    foundationTwo: seq[Card]
    foundationThree: seq[Card]
    foundationFour: seq[Card]

type 
  ActionKind* = enum
    Flip, Move
  
  StackType* = enum
    Tableau, Foundation, Pile 
  
  # todo find better abstraction than this tuple union
  StackData = tuple
    kind: StackType
    n: int
    m: int


type
  MoveOutcome = enum
    Success, Invalid
proc getSimpleCardFace(card: Card): string
proc getCardColor(card: Card): Color
proc toCardString(card: Card, simple = DRAW_SIMPLE): string
proc getCardColorStr(card: Card): string
proc cardAtTableau(state: KlondikeState, i: int, n: int = 1): Option[Card]
proc cardAtFoundation(state: KlondikeState, i: int): Option[Card] = 
  assert(0 <= i and i < 4)
  var foundation = 
    if i == 0:
      state.foundationOne
    elif i == 1:
      state.foundationTwo
    elif i == 2:
      state.foundationThree
    else:
      state.foundationFour
  if foundation.len() > 0:
    result = some(foundation[0])
  else:
    result = none(Card)

proc takeAtTableau(state: var KlondikeState, i: int, n: int = 1): seq[Card] = 
  assert(0 <= i and  i < 7)
  assert(n > 0)
  if i == 0:
    result = state.tableauOne[0..<n]
    state.tableauOne.delete(0..<n)
  elif i == 1:
    result = state.tableauTwo[0..<n]
    state.tableauTwo.delete(0..<n)
  elif i == 2:
    result = state.tableauThree[0..<n]
    state.tableauThree.delete(0..<n)
  elif i == 3:
    result = state.tableauFour[0..<n]
    state.tableauFour.delete(0..<n)
  elif i == 4:
    result = state.tableauFive[0..<n]
    state.tableauFive.delete(0..<n)
  elif i == 5:
    result = state.tableauSix[0..<n]
    state.tableauSix.delete(0..<n)
  else:
    result = state.tableauSeven[0..<n]
    state.tableauSeven.delete(0..<n)

proc addAllToTableau(state: var KlondikeState, i: int, cards: seq[Card]): void = 
  assert(0 <= i and  i < 7)
  if i == 0:
    state.tableauOne.insert(cards,0)
  elif i == 1:
    state.tableauTwo.insert(cards,0)
  elif i == 2:
    state.tableauThree.insert(cards,0)
  elif i == 3:
    state.tableauFour.insert(cards,0)
  elif i == 4:
    state.tableauFive.insert(cards,0)
  elif i == 5:
    state.tableauSix.insert(cards,0)
  else:
    state.tableauSeven.insert(cards,0)

# proc getFirst(stack: seq[Card]): Option[Card}

proc takeAtFoundation(state: var KlondikeState, i: int): Option[Card] =
  assert(0 <= i and i < 4)
  
  var foundation = 
    if i == 0:
      state.foundationOne
    elif i == 1:
      state.foundationTwo
    elif i == 2:
      state.foundationThree
    else:
      state.foundationFour
  
  if foundation.len() > 0:
    result = some(foundation[0])
    foundation.delete(0)
  else:
    result = none(Card)

  assert(0 <= i and i < 4)  
  if i == 0:
    state.foundationOne.delete(0)
  elif i == 1:
    state.foundationTwo.delete(0)
  elif i == 2:
    state.foundationThree.delete(0)
  else:
    state.foundationFour.delete(0)

proc hasSameSuit(a: Card, b: Card): bool = 
  a.suit == b.suit

proc hasSameColor(a: Card, b: Card): bool = 
  a.getCardColor() == b.getCardColor()

proc canAddCardToFoundation(foundation: seq[Card], card: Card): bool =
  if foundation.len() == 0:
    return card.face == 0
  else:
    if card.face - foundation[0].face == 1 and card.hasSameSuit(foundation[0]):
      true
    else:
      false

proc canAddCardToFoundation(state: var KlondikeState, i: int, card: Card): bool =
  assert(0 <= i and i < 4)  
  if i == 0:
    state.foundationOne.canAddCardToFoundation(card)
  elif i == 1:
    state.foundationTwo.canAddCardToFoundation(card)
  elif i == 2:
    state.foundationThree.canAddCardToFoundation(card)
  else:
    state.foundationFour.canAddCardToFoundation(card)

proc addToFoundation(state: var KlondikeState, i: int, card: Card): void =
  assert(0 <= i and i < 4)  
  if i == 0:
    state.foundationOne.insert(card,0)
  elif i == 1:
    state.foundationTwo.insert(card,0)
  elif i == 2:
    state.foundationThree.insert(card,0)
  elif i == 3:
    state.foundationFour.insert(card,0)
  

proc handleMoveBetweenTableaus(state: var KlondikeState, source: int, dest: int, amount: int): MoveOutcome = 
  if not (0 <= source and source < 7):
      echo "move: source is not in bounds"
      result = MoveOutcome.Invalid 
  elif not (0 <= dest and dest < 7):
      echo "move: dest is not in bounds"
      result = MoveOutcome.Invalid
  elif source == dest:
      echo "Illegal move"
      result = MoveOutcome.Invalid
  else:
    var cardOpOne = state.cardAtTableau(source, amount)
    var cardOpTwo = state.cardAtTableau(dest)
    if cardOpOne.isNone(): 
      if cardOpOne.isNone():
        echo fmt"there is no card at tableau {source} at depth {amount}"
      result = MoveOutcome.Invalid
      return
    
    var cardOne = cardOpOne.get()
    if cardOpTwo.isNone():
      var stack = state.takeAtTableau(source, amount)
      state.addAllToTableau(dest, stack)
      result = MoveOutcome.Success
      return
    if cardOpTwo.isSome():
      var cardTwo = cardOpTwo.get()
      if not cardTwo.flip:
        result = MoveOutcome.Invalid
        return

      echo fmt"Move: {cardOne.getSimpleCardFace()} {cardTwo.getSimpleCardFace()}"
      if getCardColor(cardOne) == getCardColor(cardTwo):
        var
          cOneStr = getCardColorStr(cardOne)
          cTwoStr = getCardColorStr(cardTwo)
        echo fmt"Illegal move: Cannot move {cOneStr} card on {cTwoStr} card"
        result = MoveOutcome.Invalid
      elif cardTwo.face - cardOne.face != 1:
        echo fmt"Illegal move: Cannot move {cardOne.getSimpleCardFace()} on {cardTwo.getSimpleCardFace()}"
        result = MoveOutcome.Invalid
      else:
        var stack = state.takeAtTableau(source, amount)
        state.addAllToTableau(dest, stack)
        result = MoveOutcome.Success

  echo result



proc popPile(state: var KlondikeState): void  =
  if state.pile.len() > 0:
    state.pile.delete(state.pile.len()-1)
  if state.pile.len() > 0:
    state.pile[state.pile.len()-1].flip = true

proc getTopOfPile(state: KlondikeState): Option[Card] =
  if state.pile.len() > 0:
    result = some(state.pile[state.pile.len()-1])
  else:
    result = none(Card)

proc isValid(stackData: StackData): bool =
  case stackData.kind:
  of StackType.Tableau:
    0 <= stackData.n and stackData.n < 7
  of StackType.Foundation:
    0 <= stackData.n and stackData.n < 4
  else:
    true


proc dealPileToStack(state: var KlondikeState, source: StackData): MoveOutcome = 
  if not source.isValid():
    result = MoveOutcome.Invalid
    return
  echo "starting dealing pile to stack" 
  let cardOptional = state.getTopOfPile()
  echo cardOptional
  if cardOptional.isSome:
    let card = cardOptional.get()
    if not card.flip:
      result = MoveOutcome.Invalid
      return
    case source.kind:
    of StackType.Tableau:
      echo "inside"
      let toMoveTo = state.cardAtTableau(source.n)
      echo toMoveTo
      if toMoveTo.isNone:
        state.popPile()
        state.addAllToTableau(source.n, @[card])
        result = MoveOutcome.Success
      else:
        var cardTwo = toMoveTo.get()
        let cardOne = card
        if not cardTwo.flip:
          result = MoveOutcome.Invalid
          return

        echo fmt"Move: {cardOne.getSimpleCardFace()} {cardTwo.getSimpleCardFace()}"
        if getCardColor(cardOne) == getCardColor(cardTwo):
          var
            cOneStr = getCardColorStr(cardOne)
            cTwoStr = getCardColorStr(cardTwo)
          echo fmt"Illegal move: Cannot move {cOneStr} card on {cTwoStr} card"
          result = MoveOutcome.Invalid
        elif cardTwo.face - cardOne.face != 1:
          echo fmt"Illegal move: Cannot move {cardOne.getSimpleCardFace()} on {cardTwo.getSimpleCardFace()}"
          result = MoveOutcome.Invalid
        else:
          state.popPile()
          state.addAllToTableau(source.n, @[cardOne])
          result = MoveOutcome.Success

    of StackType.Foundation:
      echo "inside foundation"
      if state.canAddCardToFoundation(source.n, card):
        echo fmt"can move {card.toCardString()} onto "
        state.popPile()
        state.addToFoundation(source.n, card)
        result = MoveOutcome.Success
      else:
        result = MoveOutcome.Invalid
    else:
      result = MoveOutcome.Invalid
  
proc canOverlayAsTableau(a: Card, b: Card): bool =
  not hasSameColor(a,b) and b.face - a.face == 1 

proc canOverlayAsFoundation(a: Card, b: Card): bool =
  hasSameSuit(a,b) and a.face - b.face == 1

proc moveStack(state: var KlondikeState, source: StackData, dest: StackData): MoveOutcome = 
  # refactor soon
  result = MoveOutcome.Invalid
  if source.kind == dest.kind and source.kind == StackType.Tableau:
    result = handleMoveBetweenTableaus(state, source.n, dest.n, source.m) 
  elif source.kind == StackType.Pile and dest.kind == StackType.Tableau:
    echo "moving pile to tableau"
    result = state.dealPileToStack(dest)
  elif source.kind == StackType.Pile and dest.kind == StackType.Foundation:
    result = state.dealPileToStack(dest)
  elif source.kind == StackType.Foundation and dest.kind == StackType.Tableau:
    let toMove = state.cardAtFoundation(source.n)
    let onDest = state.cardAtTableau(dest.n)
    echo onDest, toMove
    if toMove.isNone:
      result = MoveOutcome.Invalid
      return
    # check if card an be placed at source
    let card = toMove.get()
    if onDest.isNone:
      # add foundation card to empty tableau
        discard state.takeAtFoundation(source.n)
        state.addAllToTableau(dest.n, @[card])
        result = MoveOutcome.Success
        return
    else:
      let onDestCard = onDest.get()
      if canOverlayAsTableau(card, onDestCard):
        discard state.takeAtFoundation(source.n)
        state.addAllToTableau(dest.n, @[card])
        result = MoveOutcome.Success
        return
  elif source.kind == StackType.Tableau and dest.kind == StackType.Foundation:
    let toMove = state.cardAtTableau(source.n)
    let onDest = state.cardAtFoundation(dest.n)

    if toMove.isNone:
      result = MoveOutcome.Invalid
      return
    # check if card an be placed at source
    let card = toMove.get()
    if onDest.isNone and state.canAddCardToFoundation(dest.n, card):
      # add foundation card to empty foundation
        discard state.takeAtTableau(source.n, 1)
        state.addToFoundation(dest.n, card)
        result = MoveOutcome.Success
        return
    elif state.canAddCardToFoundation(dest.n, card):
      discard state.takeAtTableau(source.n, 1)
      state.addToFoundation(dest.n, card)
      result = MoveOutcome.Success
      return


# wraps a string with red ansi 
proc red*(s: string): string = "\e[31m" & s & "\e[0m"

# wraps a string wtih black ansi
proc black*(s: string): string = "\e[0m" & s & "\e[0m"

# todo: need to implement
proc validateGame(state: KlondikeState): bool =
  true

# constructs an empty state
proc emptyKlondikeState(): KlondikeState =
  KlondikeState(
      playing: false,
      deck: @[],
      pile: @[],
      tableauOne: @[],
      tableauTwo: @[],
      tableauThree: @[],
      tableauFour: @[],
      tableauFive: @[],
      tableauSix: @[],
      tableauSeven: @[],
      foundationOne: @[], 
      foundationTwo: @[], 
      foundationThree: @[], 
      foundationFour: @[], 
    )

# gets the utf8 variant of a card, with ansi color
proc getUtfCardFace(card: Card): string =
  if not card.flip:
    return PLAYING_CARD_BACK

  let(suit, face) = (card.suit, card.face)
  let suitList = 
    case suit
      of Hearts:
        ["🂱","🂲","🂳","🂴","🂵","🂶","🂷","🂸","🂹","🂺","🂻","🂽","🂾"]
      of Spades:
        ["🂡","🂢","🂣","🂤","🂥","🂦","🂧","🂨","🂩","🂪","🂫","🂭","🂮"]
      of Diamonds:
        ["🃁","🃂","🃃","🃄","🃅","🃆","🃇","🃈","🃉","🃊","🃋","🃍","🃎"]
      of Clubs:
        ["🃑","🃒","🃓","🃔","🃕","🃖","🃗","🃘","🃙","🃚","🃛","🃝","🃞"]
     
  var str = suitList[face]
  if card.getCardColor() == Color.Red:
    return str.red()
  else:
    return str.black() 

# returns the simple representation of a Face
proc toSimpleRep(face: Face): string = 
  return case face:
        of 0:
          "A"
        of 10:
          "J"
        of 11:
          "Q"
        of 12:
          "K"
        else:
          $(face + 1)

# returns the simple representation of a Suit
proc toSimpleRep(suit: Suit): string = 
 return case suit:
      of Suit.Hearts:
        "♡"
      of Suit.Diamonds:
        "♢"
      of Suit.Spades:
        "♤"
      else:
        "♧"

# returns the simple (and readable dependeing on font) representation of a card
proc getSimpleCardFace(card: Card): string = 
  if not card.flip:
    return "[==]".black()
  else:
    
    let face = card.face.toSimpleRep()
    let suit = card.suit.toSimpleRep()
    
    let str = fmt"[{face}{suit}]"
    if card.getCardColor() == Color.Red:
      return str.red()
    else:
      return str.black()

# returns an shuffled deck of cards
proc getRandomDeck(): seq[Card] =
  var deck: seq[Card] = @[]
  for kind in Suit:
    for i in Face.low..Face.high:
      let c = Card(suit: kind, face: i, flip: false)
      deck.add(c)
  
  shuffle(deck)
  return deck


proc toCardString(card: Card, simple = DRAW_SIMPLE): string = 
  if simple:
    card.getSimpleCardFace()
  else:
    card.getUtfCardFace()


proc getSavedState(): KlondikeState =
  let f = open(".klondike_game")
  defer: f.close()

  let data = f.readAll()
  data.to[:KlondikeState]

proc getCardStackString(s: seq[Card], simple = false, reverse = false): string =
  var acc = ""

  if reverse:
    for idx in countdown(s.len()-1,0):
      var i = s[idx]
      acc = acc & i.toCardString(simple)
    return if len(acc) == 0 : "[]" else: acc


  for i in s:
    acc = acc & i.toCardString(simple) 
  return if len(acc) == 0 : "[]" else: acc   

proc drawPile(state: KlondikeState, short = false, simple = false): void = 
  if not short:
    echo(getCardStackString(state.pile, simple, true))
  else:
    var l = state.pile.len()
    var str = 
      if l > 0: 
        fmt"{state.pile[^1].toCardString(simple)}|{state.pile.len()}"
      else:
        $l

    echo str

proc drawFoundations(state: KlondikeState, simple = false): void =
  let foundations = [state.foundationOne, state.foundationTwo, state.foundationThree, state.foundationFour]
  var agg = ""
  var help = ""
  var empty = if not simple: "░" else :"░░░░"
  for (idx, foundation) in enumerate(foundations):
    if foundation.len() > 0:
      agg = agg & foundation[0].toCardString(simple)
    else:
      agg = agg & empty.red()
    
    agg = agg & " "
    help = help & (if not simple: $idx else: fmt" F{idx} ") & " " 

  echo agg
  echo help

proc borderSize(n: int): string =
  var agg = ""
  for i in countup(0,n-1):
    agg = agg & "="
  agg

proc drawAscii(state: KlondikeState, simple = DRAW_SIMPLE) = 
  let size = if not simple: 7 else: 7 * 4
  let border = borderSize(size) 
  echo border
  # draw pile
  drawPile(state, true, simple) 
  echo ""

  # draw foundations
  drawFoundations(state, simple)

  # draw tableaus
  let emptySpace = if not simple: 1 else: 4
  var i = 0
  var l = 0
  let tableaus = [state.tableauOne,state.tableauTwo,state.tableauThree,state.tableauFour,state.tableauFive,state.tableauSix,state.tableauSeven]
  
  for t in tableaus:
    l = max(l, tableaus.len())

  var row = ""
  while i < 52 and l >= 0:
    for tableau in tableaus: 
      if l < len(tableau):
        
        var face = if not simple: tableau[l].getUtfCardFace() else: tableau[l].getSimpleCardFace()
        
        if tableau[l].flip and getCardColor(tableau[l]) == Color.Red:
          face = face.red()
        else:
          face = face.black()        
        row = row & face.red
      else:
        for i in countup(0, emptySpace-1):
          row = row & " "
      i = i + 1

    echo row
    row = ""
    l = l - 1

  # draw helper text
  var c = 0
  var acc = ""
  for tableau in tableaus:
    if simple:
      acc = acc & fmt" T{c} "
    else:
      acc = acc & $c
    c = c + 1
  echo acc
  echo border


proc debugBoard*() = 
  let state = getSavedState()
  var deck = getCardStackString(state.deck)
  var count = 0 
  proc debugCardStack(name: string, stack: seq[Card]): void =
    echo fmt"{name} = {stack.getCardStackString()}"
    echo fmt"{name} has {stack.len()} cards"
    echo ""
    count = count + stack.len()

  
  debugCardStack "deck", state.deck
  
  debugCardStack "tableauOne", state.tableauOne
  debugCardStack "tableauTwo", state.tableauTwo
  debugCardStack "tableauThree", state.tableauThree
  debugCardStack "tableauFour", state.tableauFour
  debugCardStack "tableauFive", state.tableauFive
  debugCardStack "tableauSix", state.tableauSix
  debugCardStack "tableauSeven", state.tableauSeven
  debugCardStack "foundationOne", state.foundationOne
  debugCardStack "foundationTwo", state.foundationTwo
  debugCardStack "foundationThree", state.foundationThree
  debugCardStack "foundationFour", state.foundationFour
  debugCardStack "pile", state.pile
  
  echo "total cards = ", count


  drawAscii(state)
 

proc showBoard*(simple = DRAW_SIMPLE) = 
  let state = getSavedState()
  var deck = getCardStackString(state.deck)
  drawAscii(state, simple)

proc gameFileExists(): bool = 
  let filePath = ".klondike_game"
  return fileExists(filePath)

proc saveGameFile(state: KlondikeState) =
  writeFile(".klondike_game", $$state)

proc init*() =
  echo "initializing game..."
  let game: KlondikeState = KlondikeState(deck: getRandomDeck())
  saveGameFile(game) 

proc packup*() =
  echo "You pack up your cards."
  echo "TODO: delete game file"
  removeFile(".klondike_game")

proc inspect*() =
  if gameFileExists():
    showBoard()
  else:
    echo "no game file found :("

proc ifGameExists*(): Option[KlondikeState] = 
  if gameFileExists():
    var state = getSavedState()
    return some(state)
  else:
    echo "game file doesnt exist"
    return none(KlondikeState)

proc getTableau(state: KlondikeState, i: int): seq[Card] = 
  assert(0 <= i and  i < 7)
  if i == 0:
    return state.tableauOne
  elif i == 1:
    return state.tableauTwo
  elif i == 2:
    return state.tableauThree
  elif i == 3:
    return state.tableauFour
  elif i == 4:
    return state.tableauFive
  elif i == 5:
    return state.tableauSix
  else:
    return state.tableauSeven


proc addToTableau(state: var KlondikeState, i: int, card: Card): void = 
  assert(0 <= i and  i < 7)
  if i == 0:
    state.tableauOne.insert(card,0)
  elif i == 1:
    state.tableauTwo.insert(card,0)
  elif i == 2:
    state.tableauThree.insert(card,0)
  elif i == 3:
    state.tableauFour.insert(card,0)
  elif i == 4:
    state.tableauFive.insert(card,0)
  elif i == 5:
    state.tableauSix.insert(card,0)
  else:
    state.tableauSeven.insert(card,0)


proc flipCard(card: var Card): void = 
  card.flip = true

proc flipTopCardInSeq(stack: var seq[Card]): void = 
  if stack.len() > 0 and stack[0].flip == false:
    flipCard(stack[0])

proc flipFromTableau(state: var KlondikeState, i: int): void = 
  assert(0 <= i and  i < 7)
  if i == 0:
    flipTopCardInSeq(state.tableauOne)
  elif i == 1:
    flipTopCardInSeq(state.tableauTwo)
  elif i == 2:
    flipTopCardInSeq(state.tableauThree)
  elif i == 3:
    flipTopCardInSeq(state.tableauFour)
  elif i == 4:
    flipTopCardInSeq(state.tableauFive)
  elif i == 5:
    flipTopCardInSeq(state.tableauSix)
  else:
    flipTopCardInSeq(state.tableauSeven)


proc removeFromTableau(state: var KlondikeState, i: int, take: int = 1): void = 
  assert(0 <= i and  i < 7)
  if i == 0:
    state.tableauOne.delete(0)
  elif i == 1:
    state.tableauTwo.delete(0)
  elif i == 2:
    state.tableauThree.delete(0)
  elif i == 3:
    state.tableauFour.delete(0)
  elif i == 4:
    state.tableauFive.delete(0)
  elif i == 5:
    state.tableauSix.delete(0)
  else:
    state.tableauSeven.delete(0)



proc cardAtTableau(state: KlondikeState, i: int, n: int = 1): Option[Card] =
  if 0 <= i and i < 7:
    var tableau = state.getTableau(i)
    if tableau.len() > (n - 1):
      return some(tableau[n - 1])
  return none(Card)

proc getCardColor(card: Card): Color = 
  return if card.suit == Diamonds or card.suit == Hearts: Color.Red else: Color.Black

proc getCardColorStr(card: Card): string = 
  return if getCardColor(card) == Color.Red: "Red" else: "Black"



proc moveCardsLegacy*(colOne: int, colTwo: int): void = 
  let game = ifGameExists()
  if game.isSome:
    var state = game.get()
    var outcome = state.moveStack((StackType.Tableau, colOne, 1), (StackType.Tableau, colTwo, 0))
    
    if outcome == MoveOutcome.Success:
      drawAscii(state)
      saveGameFile(state)
    else:
      echo "error dude"

  echo "done"

proc parseMoveToken(token: string): Option[StackData] =
  if token.len() >= 1:
    let key = token[0]
    case key:
    of 'f':
      let num = try: token[1..1].parseInt()
                except ValueError: -1
      if num >= 0 and num < 4:
        result = some((StackType.Foundation, num, 0)) 
    of 't':
      let num = try: token[1..1].parseInt()
                except ValueError: -1
      let amount =  try: 
                      if len(token) > 2: 
                        token[2..<len(token)].parseInt() 
                      else: 
                        1
                    except ValueError: 1

      if num >= 0 and num < 7:
        result = some((StackType.Tableau, num, amount))
    of 'p':
        result = some((StackType.Pile, 0,0))
    else:
      result = none(StackData)
    

proc moveCards*(token1: string, token2: string): void = 
  

  let game = ifGameExists()
  if game.isSome:
    var state = game.get()
    let stackOne = parseMoveToken(token1)
    let stackTwo = parseMoveToken(token2)
    if stackOne.isSome and stackTwo.isSome:
      let s1 = stackOne.get()
      let s2 = stackTwo.get()
      if state.moveStack(s1, s2) ==  MoveOutcome.Invalid:
        echo "no change"
      else:
        saveGameFile(state)
    else:
      echo stackOne, stackTwo
  else:
    echo "error dude"

  echo "done"

proc flipCard*(col: int): void = 
  if not (0<= col and col < 7):
    echo "flip: col is not in bounds"
    return

  let game = ifGameExists()
  if game.isSome:
    var state = game.get()
    var cardInQuestion = state.cardAtTableau(col).get()
    log(fmt"trying to flip card {cardInQuestion.getSimpleCardFace()}")
    if not cardInQuestion.flip:
      log("flipping")
      flipFromTableau(state, col)
      saveGameFile(state)
    else:
      echo "Cannot flip card that is already facing up"

proc iterateThroughPile(state: var KlondikeState): void = 
  if state.pile.len() > 1:
    if state.pile[^1].flip == false:
      state.pile[^1].flip = true
    else:
      var card = state.pile.pop()
      card.flip = false
      state.pile[^1].flip = true
      state.pile.insert(card, 0)


proc resetPile(state: var KlondikeState): void = 
  for i in 0..(len(state.pile) - 1) :
    state.pile[i].flip = false

proc pileCmd*(cmd: string = ""): void = 
  let game = ifGameExists()
  if game.isSome:
    var state = game.get()
    case cmd:
    of "reset":
      resetPile(state)
    of "next":
      iterateThroughPile(state)
    of "test":
      for i in 0..len(state.pile):
        echo fmt"{i} | {state.pile.getCardStackString(true)}"
        iterateThroughPile(state)
    else:
      echo "unknown command, just doing nothing"
    saveGameFile(state)
    drawAscii(state)


# this proc will house the interactive playing mode via a TUI
proc terminal*() =
  var 
      mesg = "Enter a string: "
      row: cint
      col: cint

  let pwin = initscr()
  getmaxyx(pwin, row, col)
  mvprintw(row div 2, (cint)((col - mesg.len) div 2), "%s", mesg)
  getstr(mesg)
  mvprintw(row - 2, 0, "You Entered: %s", mesg)
  getch()
  endwin()

proc help*() =
  echo constants.HELP_DESC

proc start*() =
  if gameFileExists():
    echo "ok starting game"
    var state = getSavedState()
    proc deal(i: int, t: var seq[Card]) = 
      var c = 0
      while c < i and state.deck.len() > 0:
        var item = state.deck[0]
        if c == 0:
          item.flip = true
        t.add(item)
        state.deck.delete(0)
        c = c + 1
    
    proc restToPile() = 
      while state.deck.len() > 0:
        state.pile.add(state.deck[0])
        state.deck.delete(0)

    state.playing = true
    deal(1, state.tableauOne)
    deal(2, state.tableauTwo)
    deal(3, state.tableauThree)
    deal(4, state.tableauFour)
    deal(5, state.tableauFive)
    deal(6, state.tableauSix)
    deal(7, state.tableauSeven)
    restToPile()

    var show = false
    saveGameFile(state)
    inspect()
    echo "finished creating game"
  else:
    echo "no game file found :("


import cli

# flip a card
# move a card(s) from one tabluau to another (if valid)
# you can move cards onto the foundations
# you can iterate / deal through the pile for a new leveraging card
# ------------------------------------
# main
#-------------------------------------
proc cliMain() =
  let cmd = cli.parseCommand(commandLineParams())
  
  if not cmd.execute():
    inspect()
  
# kind of like python
when isMainModule:
  cliMain()
