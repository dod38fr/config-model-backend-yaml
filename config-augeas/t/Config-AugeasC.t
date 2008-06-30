# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Config-AugeasC.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 15;
BEGIN { use_ok('Config::Augeas') };

package Config::Augeas;

# constants are not exported so we switch package
my $fail = 0;
foreach my $constname (qw(
	AUG_NONE AUG_SAVE_BACKUP AUG_SAVE_NEWFILE AUG_TYPE_CHECK)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Config::Augeas macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

package main;

ok( $fail == 0 , 'Constants' );
#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
ok(1,"Compilation done");

my $aug_root = 'augeas-box/';
my $lens_dir ;

foreach my $d ('/usr/local/share/augeas/lenses/') {
    $lens_dir = $d if -d $d;
}

my $augc = Config::Augeas::init($aug_root, $lens_dir) ;

ok($augc,"Created new Augeas object");

my $string = $augc->get("/files/etc/hosts/1/ipaddr") ;
is($string,'127.0.0.1',"Called get (returned $string )");

my $ret ;
$ret = $augc->set("/files/etc/hosts/2/ipaddr","192.168.0.1") ;
$ret = $augc->set("/files/etc/hosts/2/canonical","bilbo") ;

is($ret,0,"Set new host");

$ret = $augc->get("/files/etc/hosts/2/canonical") ;
is($ret,'bilbo',"Called get after set (returned $ret )");

$augc->insert("/files/etc/hosts/1", inserted_host => 1 ) ;

ok($augc,"insert new label");

$augc->set("/files/etc/hosts/3/ipaddr","192.168.0.2") ;
$augc->rm("/files/etc/hosts/3") ;
ok($augc,"removed entry");

my @a = $augc->match("/files/etc/hosts/") ;
is_deeply(\@a,["/files/etc/hosts"],"match result") ;

$ret = $augc->count_match("/files/etc/hosts/") ;
is($ret,1,"count_match result") ;

$ret = $augc->save ;
is($ret,0,"save done") ;

my $wr_dir = 'wr_test' ;
my $wr_file = "$wr_dir/print_test" ;
if (not -d $wr_dir) {
  mkdir($wr_dir,0755) || die "cannot open $wr_dir:$!";
}

open(WR, ">$wr_file") or die "cannot open $wr_file:$!";
$augc->print(WR, "/files/etc/") ;
close WR;

ok( -e $wr_file, "$wr_file exists" );

$ENV{AUG_ROOT} = $aug_root;
$ENV{AUGEAS_LENS_LIB}= $lens_dir ;

my $augc2 = Config::Augeas::init() ;

ok($augc2,"Created 2nd Augeas object");

$ret = $augc2->get("/files/etc/hosts/1/ipaddr") ;

is($ret,'127.0.0.1',"Called get (returned $ret )");
