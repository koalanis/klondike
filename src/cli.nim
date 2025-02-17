import strutils, std/strformat
import std/tables
import klondike
export klondike.log

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

proc helpCmd(ctx: CommandArgs) =
  klondike.help()

proc inspectCmd(ctx: CommandArgs) =
  klondike.inspect()

proc initCmd(ctx: CommandArgs) =
  klondike.init()
  klondike.start()

proc packupCmd(ctx: CommandArgs) =
  klondike.packup()

proc drawSimpleCmd(ctx: CommandArgs) =
  klondike.showBoard(true)

proc drawCmd(ctx: CommandArgs) =
  klondike.showBoard()

proc debugCmd(ctx: CommandArgs) =
  klondike.debugBoard()

proc flipCmd(ctx: CommandArgs) =
  let params = ctx.args
  log("trying to flip")
  var col = try: params[0].parseInt()
            except ValueError: -1
  klondike.flipCard(col)

proc moveLegacyCmd(ctx: CommandArgs) =
  let params = ctx.args
  var one = try: params[0].parseInt()
            except ValueError: -1

  var two = try: params[1].parseInt()
            except ValueError: -1
  klondike.moveCardsLegacy(one, two)

proc moveCmd(ctx: CommandArgs) = 
  if ctx.args.len() >= 2:
    klondike.moveCards(ctx.args[0], ctx.args[1])
  else:
    echo fmt"Error: not enough arguments with `{$ctx.args}`"
proc pileCmd(ctx: CommandArgs) =
  let params = ctx.args
  klondike.pileCmd(if len(params) > 0: params[0] else: "") 

proc playCmd(ctx: CommandArgs) =
  klondike.terminal()

proc shellCmd(ctx: CommandArgs)

let 
  commands = {
    "help": helpCmd,
    "check": inspectCmd,
    "inspect": inspectCmd,
    "init": initCmd,
    "packup": packupCmd,
    "draw-simple": drawSimpleCmd,
    "draw": drawCmd,
    "debug": debugCmd,
    "flip": flipCmd,
    "move": moveCmd,
    "move-legacy": moveLegacyCmd,
    "pile": pileCmd,
    "play": playCmd,
    "shell": shellCmd,
    }.newTable

proc execute*(cmd: CommandArgs): bool =
  if cmd.isEmpty():
    false
  else:
    if cmd.cmd in commands:
      commands[cmd.cmd](cmd)
      true
    else:
      false

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

