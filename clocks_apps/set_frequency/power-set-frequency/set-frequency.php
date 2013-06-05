<html>
<head>

<link rel="stylesheet" type="text/css" href="/css/fonts-min.css">
<script type="text/javascript" src="/javascript/jquery-latest.js"></script>   
<link rel='stylesheet' type='text/css' href='/css/global.css'>

<script language="javascript" type="text/javascript">

<?php 
		$supportedResolutions = null;

		if(file_exists("../../supported_resolutions.txt")==true)
		{
			$supportedResolutions = file ("../../supported_resolutions.txt",FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
	
		}

		if($supportedResolutions == null || count($supportedResolutions) == 0)
		{
			echo "supported_resolutions.txt doesn't exist or is empty";
			exit; 
		}
	?>

	var supportedResolutions=new Array(); 

	<?php
		for($x = 0;$x<count($supportedResolutions);$x++)
		{
			echo "supportedResolutions[".$x."]=\"".$supportedResolutions[$x]."\";";    
		}
	?>

	var screenWidth = 0;
	var screenHeight = 0;

	for(var i=0; i<supportedResolutions.length; i++) 
	{
		var value = supportedResolutions[i].split('x');

		screenWidth = value[0];
		screenHeight = value[1];

		if(screen.width >= screenWidth && screen.height >= screenHeight)
			break;
	}

	$('head').append('<link rel="stylesheet" type="text/css" href="/css/'+screenWidth+'x'+screenHeight+'.css" />'); 

</script>

</head>
<body class="unselectable" style = "-webkit-user-select: none;-moz-user-select: none;color:white;">
<div class = 'complete_container'>
<?php

$output = shell_exec('cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies');
$output = trim($output);
$output = explode (" ",$output);

$current_freq = shell_exec('cat /proc/cpuinfo');



for($i=0;$i<count($output);$i++)
{
	
	echo "<div style = 'float:left; padding:5px;'>";
	echo "<a href = '#' value = 'setclockspeed.sh $output[$i]' class = 'myLink' ><img class = 'app_icon' src= '/apps/images/power-icon.png' ></a>";
	$output[$i] = $output[$i]/1000;
	echo "<p>Set $output[$i] Mhz</p>";
	echo "</div>";
	
}



?>

<br><br><br><br>
<div id = "freq" style = "clear:both;">
<pre><?php echo $current_freq ?></pre>
</div>
</div>



<script>


$(".complete_container").delegate("img", "mousedown", function(e)
{
//alert("mousedown");
       e.preventDefault();
});

$(".complete_container").delegate("a", "click", function(e)
{
	//alert("mouseclick");
	e.preventDefault();
	e.stopPropagation();
	update($(this).attr("value"));
}); 

function update(command)
	{
	
		//This is a fix for IE browsers. IE likes to cache Ajax results. Therefore, adding a random string will prevent the browser from caching the Ajax request. 
		var uri = "/execute-command.php?command="+encodeURIComponent(command);
	
		$.get(uri, function(data) 
		{
			fail_count = 0;
			data = jQuery.trim(data);
			$('#freq').html("<pre>"+data+"</pre>");
		})
		//If a file cant be read or some other error related to trying to retrieve this file then JQuery executes the error function.
		//This sometimes occurs when the browser tries to read the output file before output file is even created. 
		.error(function() 
		{ 
			//Might need to handle errors
		});

	}
	



</script>


</body>
</html>

