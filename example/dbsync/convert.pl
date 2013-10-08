{

    insert => sub {
        my ($sync, $slog) = @_;
        # slog:  [k1, k2, u1, u2, ts_u];
        # dlog   [k1k2,  u1, u2, u1u2, ts_u];
        my $dlog =  [ 
            $slog->[0] . $slog->[1],   
            $slog->[2],
            $slog->[3], 
            $slog->[2] . $slog->[3], 
            $slog->[4] 
        ];
        use Data::Dump;
        Data::Dump->dump($slog, $dlog);
        return $dlog;
    },

    update => sub {
        my ($sync, $slog) = @_;
        # slog:  [k1, k2, u1, u2, ts_u];
        # dlog   [ u12, ts_u, $k12 ];
        my $dlog =  [ 
            $slog->[2] . $slog->[3], 
            $slog->[4],
            $slog->[0] . $slog->[1],   
        ],
    }
};

