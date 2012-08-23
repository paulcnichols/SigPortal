package SigPortal;
use Dancer ':syntax';
use WWW::Curl::Easy;
use JavaScript::Beautifier qw(js_beautify);
use Regexp::Common qw(URI);

# string matching stuffs
use Algorithm::Diff qw(sdiff);
use String::LCSS_XS qw(lcss lcss_all);

our $VERSION = '0.1';

set 'public' => path(dirname(__FILE__), 'public');

set 'template' => 'template_toolkit';

get '/' => sub {
    template 'index.tt';
};

post '/' => sub {
  
    my %p = params;
    my @scripts;
    for my $k (keys %p) {
	if ($k =~ /^script/) {
	    my $i=0;
	    for my $s ($p{$k} =~ /<script[^>]*>(.*?)<\/script>/gsi) {
                next if $s =~ /^\s*$/;
		push @scripts, {content=>$s, source=>'raw', part=>$i++};
	    }
	    if ($i==0) {
		push @scripts, {content=>$p{$k}, source=>'raw', part=>0};
	    }
	}
	if ($k =~ /^url/) {
	    next if !($p{$k} =~ /$RE{URI}{HTTP}/);
	    
	    my $content;
	    my $content_type;
	    my $result = 0;
	    eval {
		my $curl = WWW::Curl::Easy->new;
		$curl->setopt(CURLOPT_HEADER,1);
		$curl->setopt(CURLOPT_URL, $p{$k});
		$curl->setopt(CURLOPT_WRITEDATA,\$content);
	
		# Starts the actual request
		if (($result = $curl->perform) == 0) {
		    $content_type = $curl->getinfo(CURLINFO_CONTENT_TYPE);
		}
	    };
	    if (!$@ and $result == 0) {
		if (!($content_type =~ /script/)) {
		    my $i=0;
		    for my $s ($content =~ /<script[^>]*>(.*?)<\/script>/gsi) {
                        next if $s =~ /^\s*$/;
			if (length($s)) {
			    push @scripts, {content=>$s, source=>'url', part=>$i++, url=>$p{$k}};
			}
		    }
		}
		else {
		    push @scripts, {content=>$content, source=>'url', part=>0, url=>$p{$k}};
		}
	    }
	}
    }
    
    for my $s (@scripts) {
	# optional, might not want to align on beautiful content
	#$s->{content} = js_beautify($s->{content});
	
	# initialize an empty overlap vector
	$s->{overlap} = [];
	for (my $i=0; $i < length($s->{content}); ++$i) {
	    push @{$s->{overlap}}, 0;
	}
    }

    # count the top lcs
    my $top_lcs = {};
    
    # tally up the total overlap on scripts
    for (my $i=0; $i < scalar(@scripts) - 1; ++$i) {
	for (my $j=$i+1; $j < scalar(@scripts); ++$j) {
            my @lcs = lcss_all($scripts[$i]->{content}, $scripts[$j]->{content});
            for my $l (@lcs) {
                for (my $k=0; $k < length($l->[0]); ++$k) {
                    $scripts[$i]->{overlap}->[$l->[1]+$k]++;
                    $scripts[$j]->{overlap}->[$l->[2]+$k]++;
                }

                $l->[0] =~ s/^\s+//;
                $l->[0] =~ s/\s+$//;
                $top_lcs->{$l->[0]}++ if length($l->[0]);
            }
	#    my @si = split(//, $scripts[$i]->{content});
	#    my @sj = split(//, $scripts[$j]->{content});
	#    my @d = sdiff(\@si, \@sj);
	#    my $ik=0;
	#    my $jk=0;
	#    for (my $k=0; $k < scalar(@d); ++$k) {
	#	# left string
	#	my $c = $d[$k][0];
	#	if ($c eq '-') {
	#	    $ik++;
	#	}
	#	elsif ($c eq '+') {
	#	    $jk++;
	#	}
	#	else {
	#	    $scripts[$i]->{overlap}->[$ik++]++;
	#	    $scripts[$j]->{overlap}->[$jk++]++;
	#	}
	#    }
	}
    }
    
    # find the max overlap to color everything else
    my $max = 0;
    for my $s (@scripts) {
	for my $n (@{$s->{overlap}}) {
	    $max = $n if $n > $max;
	}
    }

    # format the top substrings
    my $top = [];
    for my $lcs (sort {$top_lcs->{$b} <=> $top_lcs->{$a}} keys %$top_lcs) {
        push @$top, {count=>$top_lcs->{$lcs}, str=>$lcs};
    }

    # color code the conent
    my $aligned = [];
    for my $s (@scripts) {
	my $html='';
	for (my $i=0; $i < length($s->{content}); ++$i) {
	    $html .= sprintf(
			'<span style="background-color: rgba(0, 0, 255, %f)">%s</span>',
			$s->{overlap}->[$i] / $max,
			substr($s->{content}, $i, 1));
	}
        push @$aligned, $html;
    }
    template 'index.tt', {lcs=>$top, scripts=>$aligned};
    
};


true;
