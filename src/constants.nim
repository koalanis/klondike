let HELP_DESC* = """
klondike - a simple solitaire by koalanis
=======================================
            _    .  ,   .           .
        *  / \_ *  / \_      _  *         
         /    \  /    \,   ((        .    
    .   /\/\  /\/ :' __ \_  `  ))  *    
       /    \/  \  _/ ^  \  ))      *   
     /\/\  /\/\:~      \ |\  *       
    /    \/    --  __   \| \/ \  
   /\/\  /\/\   /  \  | / \/   \
  /    \/    \  /    ||    \   /\
/\/\  /\/\  /\/\  /\/  /\  /\ /  \
=======================================

klondike [CMD] [SUBCOMMANDS]


init - creates deck json at CWD
packup - deletes deck json at CWD

draw - draws board with utf8 cards
draw-simple - draws a more spacious and legible variant of the board

move [TN] [TM] [amount] - attempts to move card at tableau N to tableau M
flip [TN] - flips facedown card at tableau N

pile next  - cycles through pile  
pile reset - flips all pile cards over

"""
