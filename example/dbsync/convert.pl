sub {
    my ($sync, $slog) = @_;
    # slog:  [k1, k2, u1, u2, ts_u];
    # dlog   [k1k2,  u1u2, ts_u];
    return [ $slog->[0] . $slog->[1],   $slog->[2] . $slog->[3], $slog->[4] ];
};

