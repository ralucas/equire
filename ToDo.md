To Do for Help Requester
-------------------------
1. More reports and selectability for teacher side
1. Add in lesson database attachments
1. Get lesson entry to backtrack and go forward for all the lessons on that date
1. Sortability for current requests
1. Sortability and filtering for past requests for students
1. Login page UI using Stellarjs or other libs for parallax effect
1. Make charts selectable
	* Chartsjs or Highcharts for visualization of data
1. Page speed
	* minify css and js
1. Administrator dashboard to manage student and teacher users
	* Needs timezone selection/management
1. Port to phone with phonegap
1. Port to the iPad

Code for hooking up to linkm

                childProcess.exec('~/linkm/./linkm-tool --on', 
                    (error, stdout, stderr) ->
                        console.log 'stdout: ' + stdout
                        console.log 'stderr: ' + stderr
                        if error isnt null
                            console.log 'exec error: ' + error
                    )
                setTimeout () ->
                    childProcess.exec('~/linkm/./linkm-tool --off', 
                        (error, stdout, stderr) ->
                            console.log 'stdout: ' + stdout
                            console.log 'stderr: ' + stderr
                            if error isnt null
                                console.log 'exec error: ' + error
                        )
                , 5000

