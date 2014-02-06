domain_action(Utt, [Tag|List]) :-
    af(send_to_domain(Utt, Tag, List)).
