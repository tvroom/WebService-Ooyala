package WebService::Ooyala;

use 5.006;
use strict;
use warnings FATAL => 'all';
use URI::Escape qw(uri_escape);
use LWP::UserAgent;
use Carp qw(croak);
use Digest::SHA qw(sha256_base64);
use JSON;

=head1 NAME

WebService::Ooyala - Perl interface to Ooyala's API, currently only read
operations (GET requests) are supported

Support for create, update, and delete (PUT, POST, DELETE) operations will be added in future releases.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $ooyala = WebService::Ooyala->new({ api_key => $api_key, secret_key => $secret_key });

    # Grab all video assets (or at least the first page)
    my $data = $ooyala->get("assets");

    foreach my $video(@{$data->{items}}) {
        print "$video->{embed_code} $video->{name}\n";
    }

    # Get a particular video based on embed_code

    my $video = $data->get("assets/$embed_code");


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub new {
	my($class, $params) = @_;
	$params ||= {};

	my $self = {};
	$self->{api_key}    = $params->{api_key};
	$self->{secret_key} = $params->{secret_key};
	$self->{base_url}   = $params->{base_url} || "api.ooyala.com";
	$self->{cache_base_url} =
		$params->{cache_base_url} || "cdn-api.ooyala.com";
	$self->{expiration}  = $params->{expiration}  || 15;
	$self->{api_version} = $params->{api_version} || "v2";
	$self->{agent} =
		LWP::UserAgent->new(
		agent => "perl/$], WebService::Ooyala/" . $VERSION);

	bless $self, $class;

}

sub expires {
	my($self) = @_;
	my $now_plus_window = time() + $self->{expiration};
	return $now_plus_window + 300 - ($now_plus_window % 300);
}

sub send_request {
	my($self, $http_method, $relative_path, $body, $params) = @_;

	my $path = "/" . $self->{api_version} . "/" . $relative_path;

# TODO Convert the body to JSON format
#         json_body = ''
#                 if (body is not None):
#                             json_body = json.dumps(body) if type(body) is not str else body
#
	my $json_body = {};

	my $url =
		$self->build_path_with_authentication_params($http_method, $path,
		$params, "");

	# CHECK
	if (!$url) {
		return undef;
	}

	my $base_url;
	if ($http_method ne 'GET') {
		$base_url = $self->{base_url};
	} else {
		$base_url = $self->{cache_base_url};
	}

	print "$base_url$url\n";

	my $resp;
	if ($http_method eq 'GET') {
		$resp = $self->{agent}->get("https://" . $base_url . $url);

		if ($resp->is_success) {
			return decode_json($resp->decoded_content);
		}
	}
}

sub generate_signature {
	my($self, $http_method, $path, $params, $body) = @_;
	$body ||= '';

	my $signature = $self->{secret_key} . uc($http_method) . $path;

	foreach my $key (sort keys %$params) {
		$signature .= $key . "=" . $params->{$key};
	}

# TODO This is neccesary on python 2.7. if missing, signature+=body with raise an exception when body are bytes (image data)
#         signature = signature.encode('ascii')
#                 signature += body
#                         signature = base64.b64encode(hashlib.sha256(signature).digest())[0:43]
#                                 signature = urllib.quote_plus(signature)
	$signature = sha256_base64($signature);
	return $signature;
}

sub get {
	my($self, $path, $params) = @_;
	return $self->send_request('GET', $path, '', $params);
}

sub build_path {
	my($self, $path, $params) = @_;
	my $url = $path . '?';
	foreach (keys %$params) {
		$url .= "&$_=" . uri_escape($params->{$_});
	}
	return $url;
}

sub build_path_with_authentication_params {
	my($self, $http_method, $path, $params, $body) = @_;

# TODO
#if (http_method not in HTTP_METHODS) or (self.api_key is None) or (self.secret_key is None):
#           return None

	$params ||= {};
	my $authentication_params = {%$params};
	$authentication_params->{api_key} = $self->{api_key};
	$authentication_params->{expires} = $self->expires();
	$authentication_params->{signature} =
		$self->generate_signature($http_method, $path,
		$authentication_params, $body);
	return $self->build_path($path, $authentication_params);

}

sub get_api_key {
	my $self = shift;
	return $self->{api_key};
}

sub set_api_key {
	my($self, $api_key) = @_;
	$self->{api_key} = $api_key;
}

sub get_secret_key {
	my $self = shift;
	return $self->{secret_key};
}

sub set_secret_key {
	my($self, $secret_key) = @_;
	$self->{secret_key} = $secret_key;
}

sub get_base_url {
	my $self = shift;
	return $self->{base_url};
}

sub set_base_url {
	my($self, $base_url) = @_;
	$self->{base_url} = $base_url;
}

sub get_cache_base_url {
	my $self = shift;
	return $self->{cache_base_url};
}

sub set_cache_base_url {
	my($self, $cache_base_url) = @_;
	$self->{cache_base_url} = $cache_base_url;
}

sub get_expiration_window {
	my $self = shift;
	return $self->{expiration};
}

sub set_expiration_window {
	my($self, $expiration) = @_;
	$self->{expiration} = $expiration;
}

sub del_expiration_window {
	my $self = shift;
	$self->{expiration} = 0;
}

=head1 AUTHOR

Tim Vroom, C<< <vroom at blockstackers.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-ooyala at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Ooyala>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Ooyala


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Ooyala>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Ooyala>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Ooyala>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Ooyala/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Tim Vroom.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of WebService::Ooyala
