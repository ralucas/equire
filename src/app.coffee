# Module dependencies.
express = require 'express'
routes = require './../routes'
http = require 'http'
path = require 'path'
fs = require 'fs'
util = require 'util'
socketio = require 'socket.io'
mongoose = require 'mongoose'
moment = require 'moment'
passport = require 'passport'
GoogleStrategy = require('passport-google').Strategy
client = require('twilio')('ACe1b7313b5b376f66c4db568dfa97e3e9', '1a3442ad88426e0561ed5d4fd4ae71e1')
sys = require 'sys'
childProcess = require 'child_process'
_ = require 'underscore'
momentTZ = require 'moment-timezone'

app = express()

#all environments
app.set 'port', process.env.PORT || 3000
app.set 'views', __dirname + './../views'
app.set 'view engine', 'jade'
app.use express.favicon()
app.use express.logger('dev')
app.use express.cookieParser()
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.session({secret: 'keyboard cat'})
app.use passport.initialize()
app.use passport.session()
app.use app.router
app.use express.static(path.join(__dirname, './../public'))

#development only
if 'development' == app.get('env')
	app.use express.errorHandler()

#create server
server = http.createServer(app)

#start web socket server
io = socketio.listen server

io.configure () ->
	io.set "transports", ["xhr-polling"]
	io.set "polling duration", 10

#connect mongoose
MongoURL = process.env.MONGOHQ_URL ? 'mongodb://localhost'
mongoose.connect MongoURL

#moment
moment().format()

#timezone - needs to communicate with client
timeZone = 'America/Denver'

#instantiate the Issue database
IssueSchema = new mongoose.Schema {
	issue: String,
	username: String,
	displayName: String,
	date: Object,
	timeStamp: Object,
	time: Object,
	totalWait: Number,
	isComplete: Boolean,
	comment: String
}

IssueSchema.pre 'save', (next) ->
	htmlEntities = (str) ->
		return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
	# loop over "this"
	# find all strings
	# encode strings
	for index, i of @
		if typeof i is 'string'
			@[index] = htmlEntities(i)
	next()

Issue = mongoose.model 'Issue', IssueSchema

#instantiate the User database
UserSchema = new mongoose.Schema {
	openId: String,
	displayName: String,
	emails: String,
	isTeacher: Boolean
}

User = mongoose.model 'User', UserSchema

#instantiate the Lesson database
LessonSchema = new mongoose.Schema {
	lesson : String,
	username: String,
	displayName: String,
	date: Object,
	timeStamp: Object,
	time: Object,
	relIssues: Object
}

LessonSchema.pre 'save', (next) ->
	htmlEntities = (str) ->
		return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
	for index, i of @
		if typeof i is 'string'
			@[index] = htmlEntities(i)
	next()

Lesson = mongoose.model 'Lesson', LessonSchema

#passport Google setup
ip = process.env.IP ? 'http://localhost:3000'
#heroku config:add IP=http://intense-dawn-1429.herokuapp.com

passport.serializeUser (user, done) ->
	done null, user

passport.deserializeUser (obj, done) ->
	done null, obj

passport.use new GoogleStrategy {
	returnURL: ip+'/auth/google/return',
	realm: ip
	},
	(identifier, profile, done) ->
		process.nextTick () ->
			User.find {emails: profile.emails[0]['value']}, (err, user) ->
				if !user.length
					User.create {
						openId: identifier,
						displayName: profile.displayName,
						emails: profile.emails[0]['value'],
						isTeacher: false
					}, (err, user) ->
						done err, user
				else
					done err, user[0]


app.get '/auth/google', passport.authenticate 'google'

app.get '/auth/google/return', passport.authenticate 'google', {
	session: true,
	successRedirect: '/account',
	failureRedirect: '/'}

#sockets on connection
io.sockets.on 'connection', (socket) ->
	console.log 'hello from your socket server'

	#socket event on issue instantiation
	socket.on 'issueObj', (issueObj) ->
		date = moment().tz(timeZone).format('L')
		timeStamp = moment().tz(timeZone).format('X')
		current_time = moment().tz(timeZone).format('lll')
		issue = new Issue({
			issue: issueObj.newIssue,
			username: issueObj.username,
			displayName: issueObj.displayName,
			date: date,
			timeStamp: timeStamp,
			time: current_time,
			isComplete: false,
			comment: 'None'
		})
		issue.save((err, issue) ->
			if err
				console.log 'errror'
			else
				console.log 'iss', issue
				###
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
				###
				#Send an SMS text message via Twilio
				###
				client.sendMessage {
					to:'+16145519436',
					from: '+13036256825',
					body: issueObj.displayName+' '+issueObj.newIssue+'.'
					}, (err, responseData) -> 
					if !err
						console.log responseData.from
						console.log responseData.body
				###
				io.sockets.emit 'issue', issue
			)
		
		
	#socket event on edit
	socket.on 'issueEditObj', (issueEditObj) ->
		Issue.findByIdAndUpdate(issueEditObj.issueId, {
			issue : issueEditObj.issue
			}, (err, issue) ->
				if err then console.log 'ERROR!' else 
					console.log 'Edited and Updated!'
					)
		io.sockets.emit 'issueEditObj', issueEditObj

	#socket event on completion of issue
	socket.on 'completeObj', (completeObj) ->
		Issue.findByIdAndUpdate(completeObj.issueId, {
			totalWait : completeObj.totalWait,
			isComplete : completeObj.isComplete
			comment : completeObj.comment
			}, (err, issue) ->
				if err
					console.log 'ERROR!' 
				else if completeObj.comment is 'Figured out on own'
					console.log 'figuredoutonown'
					#If figured out on own
					#Send an SMS text message via Twilio
					###
					client.sendMessage {
						to:'+16145519436',
						from: '+13036256825',
						body: issue.displayName+' '+completeObj.comment+'.'
						}, (err, responseData) -> 
						if !err
							console.log responseData.from
							console.log responseData.body
					###
				else
					console.log 'Completed and Updated!'
					)
		io.sockets.emit 'completeObj', completeObj

	#socket event on lesson input
	socket.on 'lessonObj', (lessonObj) ->
		date = moment().tz(timeZone).format('L')
		timeStamp = moment().tz(timeZone).format('X')
		current_time = moment().tz(timeZone).format('lll')
		lesson = new Lesson({
			lesson: lessonObj.lesson,
			username: lessonObj.username,
			displayName: lessonObj.displayName,
			date: date,
			timeStamp: timeStamp,
			time: current_time
		})
		lesson.save()

	socket.on 'lessonUpdate', (lessonUpdate) ->
		Lesson.update({ date: lessonUpdate.date }, {lesson : lessonUpdate.lesson}, 
			(err, numberAffected, raw) ->
				if err then console.log 'ERROR' else
				console.log 'The number of updated docs was ', numberAffected
				console.log 'The raw response from Mongo was ', raw
			)

###
Data Manipulation
###
# Issue.where({}).count( (err, count) ->
# 	if err
# 		console.log 'err'
# 	else
# 		issueCount = count
# 		console.log 'is', issueCount
# 	)

#splash page
app.get '/', (req, res) ->
	res.render 'login'

app.get '/account', (req, res) ->
	if req.user.isTeacher is false
		res.redirect '/student'
	else
		res.redirect '/teacher'

###
Student Routing
###

#student page
app.get '/student', (req, res) ->
	res.render 'student', {user: req.user}

#current request
app.get '/currentrequests', (req, res) ->
	res.render 'currentrequests', {user: req.user}

app.get '/currReq', (req, res) ->
	currUser = req.user._id
	Issue.find {username: currUser, isComplete: false}, (err, issues) ->
		if err then console.log 'ERROR' else
			res.send issues

#past requests
app.get '/pastrequests', (req, res) ->
	res.render 'pastrequests', {user: req.user}

app.get '/pastReq', (req, res) ->
	currUser = req.user._id
	Issue.find {username: currUser, isComplete: true}, (err, issues) ->
		if err then console.log 'ERROR' else
			res.send issues

#logout
app.get '/logout', (req, res) ->
	req.logout()
	res.redirect('/')

###
Teacher Routing
###

app.get '/teacher', (req, res) ->
	if req.user.isTeacher is false then res.redirect '/student'
	else
		res.render 'teacher', {user: req.user}

#look for incomplete issues and send them to the client
app.get '/found', (req, res) ->
	Issue.find {isComplete: false}, (err, issues) ->
		if err then console.log 'ERROR' else
			res.send issues

app.get '/reports', (req, res) ->
	if req.user.isTeacher is false then res.redirect '/student'
	else
		res.render 'reports', {user: req.user}

app.get '/summary', (req, res) ->
	if req.user.isTeacher is false then res.redirect '/student'
	else
		res.render 'summary', {user: req.user}

app.get '/reportsInfo', (req, res) ->
	Issue.find {}, (err, issues) ->
		if err then console.log 'ERROR' else
			res.send issues

app.get '/lessonInfo', (req, res) ->
	Lesson.find {}, (err, lessons) ->
		if err then console.log 'ERROR' else
			res.send lessons

#chart routing
app.get '/pieChart', (req, res) ->
	key = 'displayName'
	Issue.find( (err, issues) ->
		if err
			console.log 'ERROR'
		else
			keyCount = _.countBy(issues, key)
			res.send keyCount
		)

app.get '/lineChart', (req, res) ->
	days = []
	Issue.find( (err, issues) ->
		if err
			console.log 'ERROR'
		else
			dates = _.pluck(issues, 'date')
			for each in dates
				days.push(moment(each).format('dddd'))
			daysCount = _.countBy(days)
			res.send daysCount
		)

app.get '/charts', (req, res) ->
	if req.user.isTeacher is false then res.redirect '/student'
	else
		res.render 'charts', {user: req.user}

app.get '/builtwith', (req, res) ->
	res.render 'builtwith', {user: req.user}

#get and listen to server
server.listen(app.get('port'), () ->
  console.log 'Express server listening on port ' + app.get('port'))