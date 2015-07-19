# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Exception;
use Test::Warn;
use Test::Memory::Cycle;
use Config::Model;
use File::Path;
use File::Copy;
use Data::Dumper;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model->new();

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $arg =~ /l/ ? $TRACE : $ERROR );

ok( 1, "compiled" );

$model->create_config_class(
    name => 'Host',

    accept => [
        'list.*' => {
            type  => 'list',
            cargo => {
                type       => 'leaf',
                value_type => 'string',
            },
            accept_after => 'id',
        },
        'str.*' => {
            type       => 'leaf',
            value_type => 'uniline'
        },
        'bad.*' => {
            type       => 'leaf',
            value_type => 'uniline',
            warn       => 'gotcha',
        },
        'ot.*' => {
            type       => 'leaf',
            value_type => 'uniline',
        },

        #TODO: Some advanced structures, hashes, etc.
    ],
    element => [
        [qw/id other/] => {
            type       => 'leaf',
            value_type => 'uniline',
        },
    ] );

ok( 1, "Created new class with accept parameter" );

# set_up data

my $i_hosts = $model->instance(
    instance_name   => 'hosts_inst',
    root_class_name => 'Host',
);

ok( $i_hosts, "Created instance" );

my $i_root = $i_hosts->config_root;

is_deeply( [ $i_root->accept_regexp ], [qw/list.* str.* bad.* ot.*/], "check accept_regexp" );

is_deeply( [ $i_root->get_element_name ], [qw/id other/], "check explicit element list" );

my $load = "listA=one,two,three,four
listB=1,2,3,4
listC=a,b,c,d
str1=test
str2=of
str3=accept
str4=parameter -
";

$i_root->load($load);
ok( 1, "Data loaded" );

is_deeply( [ $i_root->fetch_element('listC')->fetch_all_values ],
    [qw/a b c d/], "check accepted list content" );

is_deeply(
    [ $i_root->get_element_name ],
    [qw/id listC listB listA other str1 str2 str3 str4/],
    "check element list with accepted parameters"
);

foreach my $oops (qw/foo=bar vlistB=test/) {
    throws_ok { $i_root->load($oops); }
    "Config::Model::Exception::UnknownElement",
        "caught unacceptable parameter: $oops";
}

### test always_warn parameter
my $bad = $i_root->fetch_element('badbad');
warning_like { $bad->store('whatever'); } qr/gotcha/, "test unconditional warn";

eval {require Text::Levenshtein::Damerau} ;
my $has_tld = ! $@ ;

SKIP: {
    skip "Text::Levenshtein::Damerau is not installed", 5 unless $has_tld;

    ### test user typo: accepted element is too close to real element
    my @shaves = qw/oter 1 other2 1 otehr 1 other23 1 oterh23 0/;
    while ( my $close_shave = shift @shaves) {
        my $expect = shift @shaves;
        if ($expect) {
            warning_like { $i_root->fetch_element($close_shave); } qr/distance/, "test $close_shave too close to 'other'";
        }
        else {
            warnings_are  { $i_root->fetch_element($close_shave); } [], "test accept $close_shave, is not too close to 'other'";
        }
    }
}

memory_cycle_ok($model);

done_testing;
