use strict;
use Module::Build;


my $build = Module::Build->new( 
         module_name  => "Acme::Numbers",
         license      => 'perl',
         version_from => 'lib/Acme/Numbers.pm',
         script       => [ ],
         requires     => {
                            'Lingua::EN::Words2Nums'  => 0, 
                            'Test::More'              => '0.62',
                        },
         create_makefile_pl => 'passthrough',
       );

$build->create_build_script;
