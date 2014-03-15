%Domain: house ************************************************
isa(domain, 'house').
isa(status, 'on').
isa(status, 'off').
isa(direction, 'nw').
isa(direction, 'w').
isa(direction, 'desk').
isa(direction, 'toilet').
isa(direction, 'e').
isa(direction, 'ne').
isa(direction, 'se').
isa(direction, 'sw').
isa(room, 'room1').
isa(room, 'master').
isa(room, 'room2').
isa(room, 'room3').
isa(room, 'corridor').
isa(room, 'pantry').
isa(room, 'kitchen').
isa(room, 'living').

%Domain: chess ************************************************
isa(domain, 'chess').
isa(position, 'a1').
isa(position, 'a2').
isa(position, 'a3').
isa(position, 'a4').
isa(position, 'a5').
isa(position, 'a6').
isa(position, 'a7').
isa(position, 'a8').
isa(position, 'b1').
isa(position, 'b2').
isa(position, 'b5').
isa(position, 'b6').
isa(position, 'b7').
isa(position, 'b8').
isa(position, 'c1').
isa(position, 'c2').
isa(position, 'c3').
isa(position, 'c4').
isa(position, 'c5').
isa(position, 'c6').
isa(position, 'c7').
isa(position, 'c8').
isa(position, 'd1').
isa(position, 'd2').
isa(position, 'd3').
isa(position, 'd4').
isa(position, 'd5').
isa(position, 'd6').
isa(position, 'd7').
isa(position, 'd8').
isa(position, 'e1').
isa(position, 'e2').
isa(position, 'e3').
isa(position, 'e4').
isa(position, 'e5').
isa(position, 'e6').
isa(position, 'e7').
isa(position, 'e8').
isa(position, 'f1').
isa(position, 'f2').
isa(position, 'f3').
isa(position, 'f4').
isa(position, 'f5').
isa(position, 'f6').
isa(position, 'f7').
isa(position, 'f8').
isa(position, 'g1').
isa(position, 'g2').
isa(position, 'g3').
isa(position, 'g4').
isa(position, 'g5').
isa(position, 'g6').
isa(position, 'g7').
isa(position, 'g8').
isa(position, 'h1').
isa(position, 'h2').
isa(position, 'h3').
isa(position, 'h4').
isa(position, 'h5').
isa(position, 'h6').
isa(position, 'h7').
isa(position, 'h8').
isa(end, 'to').

%Domain: draughts ************************************************
isa(domain, 'draughts').

%Domain: popkorn ************************************************
isa(domain, 'popkorn').
isa(mail, 'email').
isa(mail, 'mail').

%Domain: restaurant ************************************************
isa(domain, 'restaurant').
isa(food_type, chicken).
isa(cuisine, chinese).
isa(item_name, pizza).
isa(display_type, restaurants).
isa(display_type, cuisines).
isa(all,all).

%Domain: trains ************************************************
isa(domain, 'trains').
isa(train, 'Metroliner').
isa(train, 'Bullet').
isa(train, 'Northstar').
isa(city, 'Baltimore').
isa(city, 'Buffalo').
isa(city, 'Richmond').
isa(city, 'Pittsburgh').
isa(city, 'Washington').
isa(city, 'Newark').
isa(city, 'Atlanta').
isa(start, 'from').

origin('Metroliner','Buffalo').
origin('Bullet', 'Baltimore').
origin('Northstar', 'Richmond').

%Domain: movies ************************************************
isa(domain, 'movies').
isa(movie, 'bad.asx').
isa(movie,'rome.avi').
isa(movie,'swat.mov').
isa(movie,'traider.mov').
isa(movie,'David.asf').
isa(movie,'Kenshin.ogm').
isa(parameter, 'volume').
isa(parameter, 'height').
isa(parameter, 'width').

%Domain: planes ***********************************************
isa(domain, 'planes').
isa(pkg, 'gold').
isa(pkg, 'balloons').
isa(plane, 'Metroliner').
isa(plane, 'Bullet').
isa(plane, 'Northstar').
isa(city, 'Buffalo').
isa(city, 'Baltimore').
isa(city, 'Richmond').
isa(city, 'Pittsburgh').
isa(city, 'Washington').
isa(city, 'Newark').
isa(city, 'Atlanta').
isa(start, 'from').
isa(end, 'to').

origin('Metroliner','Buffalo').
origin('Bullet', 'Baltimore').
origin('Northstar', 'Richmond').
    


