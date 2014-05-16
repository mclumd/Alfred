%alfred internal file

%*************blocks*************
isa(c_move, c_verb)
isa(c_property_is, c_verb)
isa(c_syn_is, c_verb)

%c_move
has(c_move, c_s_src, c_t_src, c_s_dst, c_t_dst)
%needs(c_move, c_s_dst)
%c_move is a verb concept

%Part of the domain
%canbe(c_s_src, c_block, c_gridloc)
%canbe(c_s_dst, c_block, c_gridloc)
%justwant isa(c_gridloc, c_location)

isa(c_t_src, c_time_interval)
isa(c_t_dst, c_time_interval)

%c_property_is
has(c_property_is, c_subject, c_property)

isa(c_subject, c_block)
%use thematic roles instead of subject/object
%?isa(c_property, c_adjective) ???

%c_syn_is
has(c_syn_is, c_dirobj, c_synonym)

isa(c_subject, c_block)
isa(c_synonym, c_noun)


%*************Planes*************
isa(c_fly, c_verb)
isa(c_load, c_verb)
isa(c_unload, c_verb)

%c_fly
has(c_fly, c_s_src, c_t_src, c_s_dst, c_t_dst)
%needs(c_fly, c_s_dst)

%this would be in domain file
isa(c_s_src, c_plane)
isa(c_t_src, c_time_interval)
isa(c_s_dst, c_city)
isa(c_t_dst, c_time_interval)

%c_load
has(c_load, c_object, c_s_src, c_t_src, c_s_dst, c_t_dst)
isa(c_object, c_parcel)
isa(c_s_src, c_city)
isa(c_t_src, c_time_interval)
isa(c_s_dst, c_plane)
isa(c_t_dst, c_time_interval)

%c_unload
has(c_unload, c_object, c_s_src, c_t_src, c_s_dst, c_t_dst)
isa(c_object, c_parcel)
isa(c_s_src, c_plane)
isa(c_t_src, c_time_interval)
isa(c_s_dst, c_city)
isa(c_t_dst, c_time_interval)

%source and dest are something like "c_location"






