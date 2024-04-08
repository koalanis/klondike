import strutils, sequtils
import std/os
import marshal
import std/options, std/strformat
import std/random
import ncurses



type 
  Suit = enum
    Hearts = "Hearts", Spades = "Spades", Diamonds = "Diamonds", Clubs = "Clubs"
  Face = range[0..12]
  Card = object
    suit: Suit
    face: Face
    flip: bool
  
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

proc getSavedState(): KlondikeState =
  let f = open(".klondike_game")
  defer: f.close()

  let data = f.readAll()
  return data.to[:KlondikeState]

proc getCardStackString(s: seq[Card]): string =
  var acc = ""
  for i in s:
    acc = acc & getUtfCardFace(i)
  return if len(acc) == 0 : "[]" else: acc   

proc showBoard() = 
  let state = getSavedState()
  var deck = getCardStackString(state.deck)
  echo ""
  echo fmt"deck = {deck}"

  echo ""
  var tableauOne = getCardStackString(state.tableauOne);
  echo fmt"tableauOne = {tableauOne}"
  var tableauTwo = getCardStackString(state.tableauTwo);
  echo fmt"tableauTwo = {tableauTwo}"
  var tableauThree = getCardStackString(state.tableauThree);
  echo fmt"tableauThree = {tableauThree}"
  var tableauFour = getCardStackString(state.tableauFour);
  echo fmt"tableauFour = {tableauFour}"
  var tableauFive = getCardStackString(state.tableauFive);
  echo fmt"tableauFive = {tableauFive}"
  var tableauSix = getCardStackString(state.tableauSix);
  echo fmt"tableauSix = {tableauSix}"
  var tableauSeven = getCardStackString(state.tableauSeven);
  echo fmt"tableauSeven = {tableauSeven}"

  echo ""
  var foundationOne = getCardStackString(state.foundationOne);
  echo fmt"foundationOne = {foundationOne}"
  var foundationTwo = getCardStackString(state.foundationTwo);
  echo fmt"foundationTwo = {foundationTwo}"
  var foundationThree = getCardStackString(state.foundationThree);
  echo fmt"foundationThree = {foundationThree}"
  var foundationFour = getCardStackString(state.foundationFour);
  echo fmt"foundationFour = {foundationFour}"

  let pile = getCardStackString(state.pile)
  echo ""
  echo fmt"pile = {pile}"

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
  help()
  if gameFileExists():
    echo "game file found!"
    showBoard()
  else:
    echo "no game file found :("

proc start() =
  if gameFileExists():
    echo "ok starting game"
    var state = getSavedState()
    state.playing = true
    
    var i = 0
    while state.deck.len() > 0:
      let item  = state.deck[0]
      state.deck.delete(0)
      if i == 0:
        state.tableauOne.add(item)
      elif i <= (0+2):
        state.tableauTwo.add(item)
      elif i <= (0+2+3):
        state.tableauThree.add(item)
      elif i <= (0+2+3+4):
        state.tableauFour.add(item)
      elif i <= (0+2+3+4+5):
        state.tableauFive.add(item)
      elif i <= (0+2+3+4+5+6):
        state.tableauSix.add(item)
      elif i <= (0+2+3+4+5+6+7):
        state.tableauSeven.add(item)
      else:
        state.pile.add(item)
      i += 1

    saveGameFile(state)
  else:
    echo "no game file found :("

proc main() =
  let s = commandLineParams()
  if len(s) < 1:
    help()
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
