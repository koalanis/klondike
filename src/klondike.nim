import strutils, sequtils
import std/os


type 
  Suit = enum
    Heart, Spade, Diamonds, Clovers
  Face = range[0..13]
  Card = tuple[suit: Suit, face: Face]


type
  KlondikeState = tuple
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


proc getRandomDeck(): seq[Card] =
  var deck: seq[Card] = @[]
  for kind in Suit:
    for i in 0..13:
      let c = (kind, Face(i))
      deck.add(c)
  
  
  return deck

proc help() =
  echo "klondike - a simple solitaire by koalanis"
  echo "-----------------"
  echo ""

proc check() =
  let filePath = ".klondike_game"

  if fileExists(filePath):
    echo "The file exists.  "
    echo "🃁"
  else:
    echo "The file does not exist. U+1F0A1"

proc main() =
  let s = commandLineParams()
  if len(s) < 1:
    help()
    return
  
  let cmd = s[0]
  let params = s[1..len(s)-1]
  let c: Card = (Heart, Face(0))
  echo params
  echo c
  echo getRandomDeck()
  if cmd == "help":
    help()
    return
  elif cmd == "check":
    check()
    return

when isMainModule:
  main()