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

#connect mongoose
MongoURL = process.env.MONGOHQ_URL ? 'mongodb://localhost'
mongoose.connect MongoURL

#moment
moment().format()

#execute command line


#instantiate the Issue database
IssueSchema = new mongoose.Schema {
	issue: String,
	username: String,
	displayName: String,
	lesson: String,
	date: Object,
	timeStamp: Object,
	time: Object,
	totalWait: Object,
	isComplete: Boolean,
	comment: String
}

Issue = mongoose.model 'Issue', IssueSchema

#instantiate the User database
UserSchema = new mongoose.Schema {
	_id:{type: String, required: true}
	openId: String,
	displayName: String,
	emails: String
}

#UserSchema.plugin(findOrCreate);

User = mongoose.model 'User', UserSchema

#passport Google setup
ip = process.env.IP ? 'http://localhost:3000'
#heroku config:add IP=http://intense-dawn-1429.herokuapp.com

passport.use new GoogleStrategy {
	returnURL: ip+'/auth/google/return',
	realm: ip
	},
	(identifier, profile, done) ->
		console.log 'email', profile.emails[0]['value']
		User.find {_id: profile.emails[0]['value']}, (err, user) ->
			done err, user[0]
			console.log 'uu', user[0]
			if user.length is 0
				User.create {
					openId: identifier,
					_id: profile.emails[0]['value'],
					displayName: profile.displayName,
					emails: profile.emails[0]['value']
				}, (err, user) ->
					done err, user[0]
					return
				return
			return

passport.serializeUser (user, done) ->
	done null, user

passport.deserializeUser (obj, done) ->
	done null, obj

app.get '/auth/google', passport.authenticate 'google'

app.get '/auth/google/return', passport.authenticate 'google', {
	session: true,
	successRedirect: '/student',
	failureRedirect: '/'}

#sockets on connection
io.sockets.on 'connection', (socket) ->
	console.log 'hello from your socket server'

	#socket event on issue instantiation
	socket.on 'issueObj', (issueObj) ->
		date = moment().format('L')
		timeStamp = moment().format('X')
		current_time = moment().format('lll')
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
		issue.save()
		###
		#Send an SMS text message via Twilio
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
					###
					#If figured out on own
					#Send an SMS text message via Twilio
					client.sendMessage {
						to:'+16145519436',
						from: '+13036256825',
						body: Issue.displayName+' '+completeObj.comment+'.'
						}, (err, responseData) -> 
						if !err
							console.log responseData.from
							console.log responseData.body
					###
				else
					console.log 'Completed and Updated!'
					)
		io.sockets.emit 'completeObj', completeObj

	#socket event on lesson input, updates all requests from that day
	#need to get it to work for all going forward, set a default for that day
	socket.on 'lessonUpdate', (lessonUpdate) ->
		Issue.update({ date: lessonUpdate.date }, {lesson : lessonUpdate.lesson}, 
			(err, numberAffected, raw) ->
				if err then console.log 'ERROR' else
				console.log 'The number of updated docs was ', numberAffected
				console.log 'The raw response from Mongo was ', raw
			)

#splash page
app.get '/', (req, res) ->
	res.render 'login', {user: req.user}

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
	Issue.find {username: currUser, isComplete: false}, (err, issue) ->
		if err then console.log 'ERROR' else
			res.send issue

#past requests
app.get '/pastrequests', (req, res) ->
	res.render 'pastrequests', {user: req.user}

app.get '/pastReq', (req, res) ->
	currUser = req.user._id
	Issue.find {username: currUser, isComplete: true}, (err, issue) ->
		if err then console.log 'ERROR' else
			res.send issue	

#logout
app.get '/logout', (req, res) ->
	req.logout()
	res.redirect('/')

###
Teacher Routing
###

app.get '/teacher', (req, res) ->
	res.render 'teacher'

#look for incomplete issues and send them to the client
#Basically load unfinished requests
app.get '/found', (req, res) ->
	Issue.find {isComplete: false}, (err, issue) ->
		if err then console.log 'ERROR' else
			res.send issue

app.get '/reports', (req, res) ->
	res.render 'reports', {user: req.user}

app.get '/reportsInfo', (req, res) ->
	Issue.find {}, (err, issue) ->
		if err then console.log 'ERROR' else
			res.send issue

#get and listen to server
server.listen(app.get('port'), () ->
  console.log 'Express server listening on port ' + app.get('port'))