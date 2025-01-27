import strutils, sequtils
import std/os
import marshal
import std/options, std/strformat
import std/random
import ncurses

randomize()

const PLAYING_CARD_BACK = "🂠"

const DEBUG: bool = true


proc log(s: string) = 
  if DEBUG:
    echo s

type 
  Suit = enum
    Hearts = "Hearts", Spades = "Spades", Diamonds = "Diamonds", Clubs = "Clubs"
  
  Face = range[0..13]
  
  Card = object
    suit: Suit
    face: Face
    flip: bool
  
  Color = enum
    Red, Black


type 
  KlondikeState = object
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

proc getCardColor(card: Card): Color 

proc red*(s: string): string = "\e[31m" & s & "\e[0m"

proc black*(s: string): string = "\e[0m" & s & "\e[0m"


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
  return suitList[face]

proc toSimpleRep(face: Face): string = 
  return if 1 <= face and face < 10:
      $face
    else:
      case face:
        of 0:
          "A"
        of 10:
          "j"
        of 11:
          "k"
        of 12:
          "Q"
        else:
          "K"

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

proc getRandomDeck(): seq[Card] =
  var deck: seq[Card] = @[]
  for kind in Suit:
    for i in Face.low..Face.high:
      let c = Card(suit: kind, face: i, flip: false)
      deck.add(c)
  
  shuffle(deck)
  return deck

proc help() =
  echo "klondike - a simple solitaire by koalanis"
  echo "-----------------"
  echo PLAYING_CARD_BACK

proc getSavedState(): KlondikeState =
  let f = open(".klondike_game")
  defer: f.close()

  let data = f.readAll()
  data.to[:KlondikeState]

proc getCardStackString(s: seq[Card], simple = false): string =
  var acc = ""
  for i in s:
    acc = acc & (if simple: getSimpleCardFace(i) else: getUtfCardFace(i))
  return if len(acc) == 0 : "[]" else: acc   

proc drawAscii(state: KlondikeState, simple = false) = 
  
  # draw pile
  echo(getCardStackString(state.pile, simple))
  echo ""
  # draw foundations

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

proc debugBoard() = 
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
 

proc showBoard(simple = false) = 
  let state = getSavedState()
  var deck = getCardStackString(state.deck)
  drawAscii(state, simple)

proc gameFileExists(): bool = 
  let filePath = ".klondike_game"
  return fileExists(filePath)

proc saveGameFile(state: KlondikeState) =
  writeFile(".klondike_game", $$state)

proc init() =
  echo "creating game..."
  let game: KlondikeState = KlondikeState(deck: getRandomDeck())
  saveGameFile(game) 

proc packup() =
  echo "You pack up your cards."
  echo "TODO: delete game file"
  removeFile(".klondike_game")

proc inspect() =
  if gameFileExists():
    showBoard()
  else:
    echo "no game file found :("

proc ifGameExists(): Option[KlondikeState] = 
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


proc removeFromTableau(state: var KlondikeState, i: int): void = 
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



proc cardAtTableau(state: KlondikeState, i: int): Option[Card] =
  if 0 <= i and i < 7:
    var tableau = state.getTableau(i)
    if tableau.len() > 0:
      return some(tableau[0])
  return none(Card)

proc getCardColor(card: Card): Color = 
  return if card.suit == Diamonds or card.suit == Hearts: Color.Red else: Color.Black

proc moveCards(colOne: int, colTwo: int): void = 
  let game = ifGameExists()
  if game.isSome:
    var state = game.get()
    if not (0 <= colOne and colOne < 7):
      echo "move: colOne is not in bounds"
      return
    if not (0 <= colTwo and colTwo < 7):
      echo "move: coltwo is not in bounds"
      return
  
    if colOne == colTwo:
      echo "Illegal move"
      return
    
    var cardOne = state.cardAtTableau(colOne).get()
    var cardTwo = state.cardAtTableau(colTwo).get()
    echo fmt"Move: {cardOne.getUtfCardFace()} {cardTwo.getUtfCardFace()}"
    if getCardColor(cardOne) == getCardColor(cardTwo):
      echo "Illegal move"
      return
    if cardTwo.face - cardOne.face != 1:
      echo "Illegal move"
      return
    
    echo "Legal move"
    state.removeFromTableau(colOne)
    state.addToTableau(colTwo, cardOne)
    drawAscii(state)
    saveGameFile(state)
  echo "done"

proc flipCard(col: int): void = 
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

    


proc start() =
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



# ------------------------------------
#                  main
#-------------------------------------
proc main() =
  let s = commandLineParams()
  if len(s) < 1:
    inspect()
    return
  let cmd = s[0]
  let params = s[1..len(s)-1]

  if cmd == "help":
    help()
    return
  elif cmd == "check" or cmd == "inspect":
    inspect()
    return
  elif cmd == "init":
    init()
    return
  elif cmd == "packup":
    packup()
    return
  elif cmd == "start":
    start()
    return
  elif cmd == "draw-simple":
    showBoard(true)
  elif cmd == "debug":
    debugBoard()
    return
  elif cmd == "flip":
    log("trying to flip")
    var col = try: params[0].parseInt()
              except ValueError: -1
    flipCard(col)
    return
  elif cmd == "move":
    var one = try: params[0].parseInt()
              except ValueError: -1

    var two = try: params[1].parseInt()
              except ValueError: -1
    moveCards(one, two)
  elif cmd == "play":
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
    return 

# kind of like python
when isMainModule:
  main()
