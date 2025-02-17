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

move <t,f,p>|<n><m> <t,f,p>|<n><m> -  attempts to move card at location a to location b
ex: move t0 t1 - attempts to move card at tableau 0 to tableau 1
    move t12 t2 - attempts to move 2 cards at tableau 1 to tableau 2
    move p t0  - attempts to move top card from pile to tableau 0
    move t1 f0 - attempts to move card from tableau 1 to foundation 0

flip [N] - flips facedown card at tableau N

pile next  - cycles through pile  
pile reset - flips all pile cards over

shell - open an interactive game session
"""
