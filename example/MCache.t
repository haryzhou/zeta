use Zeta::MCache;
use Data::Dump;

my $mc = Zeta::MCache->new(
    t => 2,
    T => 2,
);

$mc->set(qw/t 1 1/);
$mc->set(qw/t 2 2/);
$mc->set(qw/t 3 3/);
$mc->set(qw/t 4 4/);
$mc->set(qw/t 5 5/);

$mc->set(qw/T 1 1/);
$mc->set(qw/T 2 2/);
$mc->set(qw/T 3 3/);
$mc->set(qw/T 4 4/);
$mc->set(qw/T 5 5/);

Data::Dump->dump($mc);

