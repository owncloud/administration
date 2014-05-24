<?php

$log = file_get_contents(__DIR__ . '/data/owncloud.log');
$logs = explode("\n", $log);

$table = array();
$requests = array();
$reqi = 0;
$caps = array();
$capi = 0;
$files = array();
$filesi = 0;
foreach($logs as $log) {
	if(trim($log) == '') continue;
	$row = json_decode($log, true);
	switch($row['app']) {
		case 'core':
			continue 2;
	}
	if(!isset($requests[$row['reqId']])) {
		$requests[$row['reqId']] = $reqi++;
	}
	$row['req'] = $requests[$row['reqId']];
	$row['cap'] = 'none';
	if(preg_match('#/\S+#', $row['message'], $cap)) {
		if(!isset($caps[$cap[0]])) {
			$caps[$cap[0]] = $capi++;
		}
		$row['cap'] = $caps[$cap[0]];
	}
	if(!isset($files[$row['url']])) {
		$files[$row['url']] = $filesi++;
	}
	$row['file'] = $files[$row['url']];
	$table[] = $row;
}


function makeColorGradient($frequency1, $frequency2, $frequency3, $phase1, $phase2, $phase3, $center, $width, $len) {
	$out = array();
	for ($i = 0; $i < $len; ++$i) {
		$red = round(sin($frequency1 * $i + $phase1) * $width + $center);
		$grn = round(sin($frequency2 * $i + $phase2) * $width + $center);
		$blu = round(sin($frequency3 * $i + $phase3) * $width + $center);
		$out[] = "rgb($red,$grn,$blu)";
	}
	return $out;
}

$colors = makeColorGradient(.7, .7, .7, 0, 2, 4, 200, 55, count($table));

?>
<!DOCTYPE HTML>
<html>

<head>

<script src="http://code.jquery.com/jquery-1.11.0.min.js"></script>
<style>
	td {
		border-bottom: 1px solid #ddd;
		vertical-align: top;
	}
	.active td {
		/* font-weight: bold; */
	}
	.inactive {
		opacity: 0.2;
	}
	.message {
		overflow-x: auto;
	}
	<?php foreach($requests as $request): ?>
	.request_<?= $request ?> {
		background-color: <?= $colors[$request] ?>;
	}
	<?php endforeach; ?>
</style>
	<script>
		$(function(){
			$('td.message').on('click', function(){
				$('tr').removeClass('active');
				$('tr').removeClass('inactive');
				var tr = $(this).closest('tr');
				var c = tr.attr('class');
				if(m = c.match(/cap_(\d+)/)) {
					$('.' + m[0]).addClass('active');
					$('tr:not(.' + m[0] + ')').addClass('inactive');
				}
			});
			$('td.sel').on('click', function() {
				$('tr').removeClass('active');
				$('tr').removeClass('inactive');
			});
			$('td.req').on('click', function(){
				$('tr').removeClass('active');
				$('tr').removeClass('inactive');
				var tr = $(this).closest('tr');
				var c = tr.attr('class');
				if(m = c.match(/request_(\d+)/)) {
					$('.' + m[0]).addClass('active');
					$('tr:not(.' + m[0] + ')').addClass('inactive');
				}
			});
			$('td.url').on('click', function(){
				$('tr').removeClass('active');
				$('tr').removeClass('inactive');
				var tr = $(this).closest('tr');
				var c = tr.attr('class');
				if(m = c.match(/file_(\d+)/)) {
					$('.' + m[0]).addClass('active');
					$('tr:not(.' + m[0] + ')').addClass('inactive');
				}
			});
		})
	</script>
	</head>
<body>
<table>
	<thead>
	<tr>
		<th>Sel</th>
		<th>reqId</th>
		<th>app</th>
		<th>message</th>
		<th>method</th>
		<th>url</th>
	</tr>
	</thead>
	<tbody>
	<?php foreach($table as $row): ?>
		<tr class="request_<?= $row['req'] ?> cap_<?= $row['cap'] ?> file_<?= $row['file'] ?>">
			<td class="sel"></td>
			<td class="req"><?= $row['req'] ?></td>
			<td><?= $row['app'] ?></td>
			<td class="message"><?= str_replace('/', '/<wbr>', $row['message']) ?></td>
			<td><?= $row['method'] ?></td>
			<td class="url"><?= str_replace('/', '/<wbr>', $row['url']) ?></td>
		</tr>
	<?php endforeach; ?>
	</tbody>
</table>
</body>
</html>
