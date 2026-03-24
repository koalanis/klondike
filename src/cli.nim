import std/sequtils, std/strutils, std/strformat
import std/tables
import klondike
export klondike.log
import constants

type
  CommandArgs* = object
    cmd: string
    args: seq[string]
  





proc isEmpty*(cmd: CommandArgs): bool =
  cmd.cmd.len() == 0

proc parseCommand*(s: seq[string]): CommandArgs =
  if s.len() > 0:
    CommandArgs(
      cmd:  s[0],
      args: s[1..len(s)-1]
    )
  else:
    CommandArgs(
      cmd: "",
      args: @[]
    )
proc helpCmd(ctx: CommandArgs)

const DESC_HELP = "provides command details and how-to guide to play game"
let onHelp = (DESC_HELP, helpCmd)

const DESC_INSPECT = "shows serialized game state"
proc inspectCmd(ctx: CommandArgs) =
  klondike.inspect()
let onInspect = (DESC_INSPECT, inspectCmd)

const DESC_INIT = "creates a game file and starts the game"
proc initCmd(ctx: CommandArgs) =
  klondike.init()
  klondike.start()
let onInit = (DESC_INIT, initCmd)

const DESC_PACKUP = "deletes game at current directory"
proc packupCmd(ctx: CommandArgs) =
  klondike.packup()
let onPackup = (DESC_PACKUP, packupCmd)

const DESC_DRAW_SIMPLE = "draws game in SIMPLE mode"
proc drawSimpleCmd(ctx: CommandArgs) =
  klondike.showBoard(true)
let onDrawSimple = (DESC_DRAW_SIMPLE, drawSimpleCmd)

const DESC_DRAW= "draws game in UTF8 mode"
proc drawCmd(ctx: CommandArgs) =
  klondike.showBoard()
let onDraw = (DESC_DRAW, drawCmd)

const DESC_DEBUG= "prints out verbose game state and invariant checks"
proc debugCmd(ctx: CommandArgs) =
  klondike.debugBoard()
let onDebug = (DESC_DEBUG, debugCmd)

const DESC_FLIP= "flips card"
proc flipCmd(ctx: CommandArgs) =
  let params = ctx.args
  log("trying to flip")
  var col = try: params[0].parseInt()
            except ValueError: -1
  klondike.flipCard(col)
let onFlip = (DESC_FLIP, flipCmd)

proc moveLegacyCmd(ctx: CommandArgs) =
  let params = ctx.args
  var one = try: params[0].parseInt()
            except ValueError: -1

  var two = try: params[1].parseInt()
            except ValueError: -1
  klondike.moveCardsLegacy(one, two)
let onMoveLegacy = ("movelegacy", moveLegacyCmd)

proc moveCmd(ctx: CommandArgs) = 
  if ctx.args.len() >= 2:
    klondike.moveCards(ctx.args[0], ctx.args[1])
  else:
    echo fmt"Error: not enough arguments with `{$ctx.args}`"
let onMove = ("move", moveCmd)

proc pileCmd(ctx: CommandArgs) =
  let params = ctx.args
  klondike.pileCmd(if len(params) > 0: params[0] else: "") 
let onPile = ("pile", cli.pileCmd)

proc playCmd(ctx: CommandArgs) =
  klondike.terminal()
let onPlay = ("play", playCmd)

proc shellCmd(ctx: CommandArgs)
let onShell = ("shell", shellCmd)

let 
  commands = {
    "help": onHelp,
    "inspect": onInspect,
    "init": onInit,
    "packup": onPackup,
    "draw-simple": onDrawSimple,
    "draw": onDraw,
    "debug": onDebug,
    "flip": onFlip,
    "move": onMove,
    "move-legacy": onMoveLegacy,
    "pile": onPile,
    "play": onPlay,
    "shell": onShell,
    }.newTable


proc execute*(cmd: CommandArgs): bool =
  if cmd.isEmpty():
    false
  else:
    if cmd.cmd in commands:
      commands[cmd.cmd][1](cmd)
      true
    else:
      false

proc helpCmd(ctx: CommandArgs) =
  if ctx.args.len() > 0:
    let target = ctx.args[0]
    if target in commands:
      echo commands[target][0]
  else:
    echo constants.ASCII_LOGO

    var str = ""
    for cmd, metadata in pairs(commands):
      str = str & fmt"{cmd:<11}" & fmt"  {metadata[0]}" & "\n" 
    echo str

proc shellCmd(ctx: CommandArgs) = 
  var running = true
  while running:
    stdout.write("> ")
    let line = stdin.readline()
    let cmd = parseCommand(line.split(" "))
    case cmd.cmd:
      of "shell":
        echo "Already in shell mode"
      of "exit":
        echo "exiting..."
        running = false
      of "":
        drawCmd(cmd)
      else:
        if not execute(cmd):
          echo fmt"command not found {cmd.cmd}"
    echo ""

