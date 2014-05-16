%planes domain file

%structure of "fly" command
dcommand(planes, fly, durationFunction).

%Fly Command structure
isa(c_fly, c_command).
needs(c_fly, v_plane, v_city).

%Load command structure
isa(c_load, c_command).
needs(c_load, v_plane, v_parcel).

%Variables
isa(v_plane, c_plane).
isa(v_city, c_city).
isa(v_parcel, c_parcel).

%lexical and concept links
refers(alfred, l_plane, c_plane).
refers(alfred, l_city, c_city).
refers(alfred, l_parcel, c_parcel).

%All references
refers(all, "plane", l_plane).
refers(all, "city", l_city).
refers(all, "parcel", l_parcel).

%Planes and cities and parcels
isa(c_Metroliner, c_plane).
isa(c_Bullet, c_plane).
isa(c_Baltimore, c_city).
isa(c_Richmond, c_city).
isa(c_Gold, c_parcel).
isa(c_Balloons, c_parcel).
 
%actual references planes (all refers to users and domain)
refers(alfred, l_Metroliner, c_Metroliner).
refers(all, "Metroliner", l_Metroliner).
refers(beth, "Metro", l_Metroliner).
refers(alfred, l_Bullet, c_Bullet).
refers(all, "Bullet", l_Bullet).

%actual references cities
refers(alfred, l_Baltimore, c_Baltimore).
refers(all, "Baltimore", l_Baltimore).
refers(alfred, l_Richmond, c_Richmond).
refers(all, "Richmond", l_Richmond).

%actual references packages
refers(alfred, l_Gold, c_Gold).
refers(all, "Gold", l_Gold).
refers(alfred, l_Balloons, c_Balloons).
refers(all, "Balloons", l_Balloons).

