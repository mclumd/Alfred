%trains domain file

%structure of "send" command
dcommand(blocks, move, durationFunction).

%send command structure
isa(c_move, c_command).
isa(c_gridloc, c_location). %for alfred to do reasoning

%Variables
isa(v_block, c_block).
isa(v_gridloc, c_gridloc).

%lexical and concept connections
refers(alfred, l_block, c_block).
refers(alfred, l_gridloc, c_gridloc).

%all is alfred and users
refers(all, "block", l_block).
refers(all, "gridloc", l_gridloc).

%train and city concepts
isa(c_block1, c_block).
isa(c_block2, c_block).

%actual references trains
refers(alfred, l_block1, c_block1).
refers(all, "Block1", l_block1).
refers(beth, "B1", l_block1).



