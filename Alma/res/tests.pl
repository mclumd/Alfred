resolve([not(p(X)), q(X)], [p(a)], r(X), C).
resolve([not(p(X)),  q(X)], [p(a), s(a)], r(X), C).
resolve([not(p(X)), not(s(X)), q(X)], [p(a)], r(X), C).
resolve([not(p(X)), not(s(X)), q(X)], [p(a), s(a)], r(X), C).
resolve([not(p(Y)), not(s(X)), q(X, Y)], [p(a), s(b)], r(X), C).

resolve([not(p(X)), q(X)], [p(a), p(b)], r(X), C).
