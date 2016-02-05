# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Path::Tiny;
use YAML::Any;

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

plan tests => 8;

ok( 1, "compiled" );

# pseudo root where config files are written by config-model
my $wr_root = path('wr_root');

# cleanup before tests
$wr_root->remove_tree;
my $yaml_dir = $wr_root->child('yaml');
$yaml_dir->mkpath();

my $i_hosts = $model->instance(
    instance_name   => 'hosts_inst',
    root_class_name => 'Hosts',
    root_dir        => $wr_root->stringify,
    model_file      => 't/test_yaml_model.pl',
);

ok( $i_hosts, "Created instance" );

my $i_root = $i_hosts->config_root;

my $load = "record:0
  ipaddr=127.0.0.1
  canonical=localhost
  alias=localhost -
record:1
  ipaddr=192.168.0.1
  canonical=bilbo - -
";

$i_root->load($load);

$i_hosts->write_back;
ok( 1, "yaml write back done" );

my $yaml_file = $yaml_dir ->child('hosts.yml');
ok( $yaml_file->exists, "check that config file $yaml_file was written" );

# create another instance to read the yaml that was just written
my $i2_hosts = $model->instance(
    instance_name   => 'hosts_inst2',
    root_class_name => 'Hosts',
    root_dir        => $wr_root->stringify,
);

ok( $i2_hosts, "Created instance" );

my $i2_root = $i2_hosts->config_root;

my $p2_dump = $i2_root->dump_tree;

is( $p2_dump, $load, "compare original data with 2nd instance data" );

# since full_dump is null, check that dummy param is not written in yaml files
my $yaml = $yaml_file->slurp || die "can't open $yaml_file:$!";

unlike( $yaml, qr/dummy/, "check yaml dump content" );

memory_cycle_ok( $model, "check model mem cycles" );
