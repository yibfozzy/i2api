package App::I2::API::Misc;

use strict;
use warnings;

use Carp;
use base 'Exporter';
use File::Slurp;
use JSON::XS;
use YAML::XS 'LoadFile';

require LWP::UserAgent;

our @EXPORT = qw(
  $icinga_url $icinga_user send_query
);

my $config = "$ENV{HOME}/.icinga";
croak "Can't find .icinga file with credentials" if !-f $config;

my $conf = LoadFile($config);

croak "The user credentials are blank!" if ( !$conf->{user}->{username} || !$conf->{user}->{password} );
croak "The API URL is missing!" if !$conf->{server}->{url};
$conf->{server}->{port} = 5665 if !$conf->{server}->{port};

our $icinga_url = 'https://' . $conf->{user}->{username} . ':' . $conf->{user}->{password} . '@' . $conf->{server}->{url} . ':' . $conf->{server}->{port} . '/v1/actions/';
our $icinga_user = $conf->{user}->{username};

sub send_query {
    my ( $url, $data, $opt ) = @_;
    my $ua = LWP::UserAgent->new();
    my $array;
    my $response = $ua->post(
      $url,
      'Accept'  => 'application/json',
      'Content' => $data
    );
    croak $response->status_line if !$response->is_success;
    my $content = decode_json( $response->content );
    if ( !$content->{error} ) {
        $array = $content->{results};
        croak "The response from API is empty!" if !@$array;
    }
    else {
        print $content->{status} . "\n";
        return;
    }
    for (@$array) {
        print $_->{status} . "\n";
    }
}

1;
