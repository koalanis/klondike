import strutils, sequtils
import std/os
import marshal
import std/options

type 
  Suit = enum
    Hearts = "Hearts", Spades = "Spades", Diamonds = "Diamonds", Clubs = "Clubs"
  Face = range[0..12]
  Card = tuple[suit: Suit, face: Face]
  KlondikeState = object
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
  let(suit, face) = card
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
      let c = (kind, Face(i))
      deck.add(c)
  
  return deck

proc help() =
  echo "klondike - a simple solitaire by koalanis"
  echo "-----------------"

proc getSavedState(): KlondikeState =
  let f = open(".klondike_game")
  defer: f.close()

  let data = f.readAll()
  return data.to[:KlondikeState]

proc showBoard() = 
  let state = getSavedState()
  var acc = ""
  for i in state.deck:
    acc = acc & getUtfCardFace(i)
  echo acc

proc gameFileExists(): bool = 
  let filePath = ".klondike_game"
  return fileExists(filePath)

proc init() =
  echo "creating game..."
  let game: KlondikeState = KlondikeState(deck: getRandomDeck())
  writeFile(".klondike_game", $$game)

proc packup() =
  echo "packing up game..."

proc check() =
  help()
  if gameFileExists():
    echo "game file found!"
    showBoard()
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
  elif cmd == "check":
    check()
    return
  elif cmd == "init":
    init()
    return
  elif cmd == "packup":
    packup()
    return

when isMainModule:
  main()