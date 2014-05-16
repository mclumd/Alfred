%trains domain file

%structure of "send" command
dcommand(trains, send, durationFunction).

%send command structure
isa(c_send, c_command).
needs(c_send, v_train, v_city).

%Variables
isa(v_train, c_train).
isa(v_city, c_city).

%lexical and concept connections
refers(alfred, l_train, c_train).
refers(alfred, l_city, c_city).

%all is alfred and users
refers(all, "train", l_train).
refers(all, "city", l_city).

%train and city concepts
isa(c_Metroliner, c_train).
isa(c_Bullet, c_train).
isa(c_Baltimore, c_city).
isa(c_Richmond, c_city).

%actual references trains
refers(alfred, l_Metroliner, c_Metroliner).
refers(all, "Metroliner", l_Metroliner).
refers(beth, "Metro", l_Metroliner).
refers(alfred, l_Bullet, c_Bullet).
refers(all, "Bullet", l_Bullet).

%actual references citiese 
refers(alfred, l_Baltimore, c_Baltimore).
refers(all, "Baltimore", l_Baltimore).
refers(alfred, l_Richmond, c_Richmond).
refers(all, "Richmond", l_Richmond).


%command structure
structure(d_send, [d_send, v_train, v_city])
isa(v_train, d_train)
isa(v_city, d_city)



isa(c_Metroliner, c_train)
change c_ links to l_ links to refers instead of isas

locomotive













