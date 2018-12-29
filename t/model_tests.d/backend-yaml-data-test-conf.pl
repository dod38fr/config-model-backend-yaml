use Config::Model::BackendMgr;
use utf8;

$conf_dir = '/etc';
$conf_file_name = 'test.yaml';

$model->create_config_class(
    name => 'Master',

    rw_config => {
        backend     => 'yaml',
        config_dir  => '/etc/',
        file        => 'test.yaml',
    },

    element => [
        true_bool  => { qw/type leaf value_type boolean upstream_default 0/},
        false_bool => { qw/type leaf value_type boolean upstream_default 0/},
        new_bool => { qw/type leaf value_type boolean upstream_default 0/},
        null_value => { qw/type leaf value_type uniline/},
        utf8_string => { qw/type leaf value_type uniline/},
    ]
);

$model_to_test = "Master";

@tests = (
    {
        name  => 'basic',
        check => [
            # values are translated from whatever YAML lib returns to true and false
            true_bool => 1,
            false_bool => 0,
            null_value => undef
        ],
        load => 'new_bool=1',
        file_contents => {
            # test that file contains real booleans
            "/etc/test.yaml" => "---\nfalse_bool: false\nnew_bool: true\ntrue_bool: true\n",
        }
    },
    {
        name => 'utf8_data',
        check => [
            utf8_string => "Марцел Mézigue"
        ],
        file_contents_like => {
            "/etc/test.yaml" => [ qr/Марцел Mézigue/ ] ,
        }
    }
);

1;
