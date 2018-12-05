
use Module::Build;

use warnings;
use strict;

require 5.010001 ;

my @version_info = @ARGV ? ( dist_version => $ARGV[0] ) : ();

my $build = Module::Build->new(
    module_name => 'Config::Model::Backend::Yaml',
    @version_info,
    license       => 'lgpl',
    dist_abstract => 'Config::Model plugin to read and write YAML files',
    dist_author   => 'Dominique Dumont (ddumont at cpan dot org)',

##{ $plugin->get_prereqs ##}

    add_to_cleanup => [ qw/wr_root/ ],
);

$build->add_build_element('pl');

$build->create_build_script;
