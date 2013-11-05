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
findOrCreate = require 'mongoose-findorcreate'
passport = require 'passport'
GoogleStrategy = require('passport-google').Strategy

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
mongoose.connect 'mongodb://localhost'
db = mongoose.connection

db.once 'open', () ->
	console.log 'alive'

#moment
moment().format()

#instantiate the Issue database
IssueSchema = new mongoose.Schema {
	issue: String,
	username: String,
	displayName: String,
	lesson: String,
	time: Object,
	isComplete: Boolean
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
passport.use new GoogleStrategy {
	returnURL: 'http://localhost:3000/auth/google/return',
	realm: 'http://localhost:3000'
	},
	(identifier, profile, done) ->
		console.log 'email', profile.emails[0]['value']
		User.find {_id: profile.emails[0]['value']}, (err, user) ->
			done err, user[0]
			console.log 'uu', user[0]
			if user.length is 0
				console.log 'uniqueUser', user[0]
				User.create {
					openId: identifier,
					_id: profile.emails[0]['value'],
					displayName: profile.displayName,
					emails: profile.emails[0]['value']
				}, (err, user) ->
					console.log 'hi'
					done err, user[0]
					return
				return
			return
			
			#if user is not found create
		# User.findOrCreate {
		# 	openId: identifier,
		# 	#_id: profile.emails[0]['value'],
		# 	displayName: profile.displayName,
		# 	emails: profile.emails[0]['value']
		# }, 
		# (err, user) ->
		# 	done err, user

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

	###
	on submission of issue, package into a new object
	that contains username, userID, issue, time, begin clock,
	category, then send it over to the teachers side
	###
	socket.on 'issueObj', (issueObj) ->
		console.log 'issueObj', issueObj
		current_time = moment().format('lll')
		issue = new Issue({
			issue: issueObj.newIssue,
			username: issueObj.username,
			displayName: issueObj.displayName,
			time: current_time,
			isComplete: false
		})
		issue.save()
		console.log 'issueDb', issue
		
		console.log 'issue saved'
		io.sockets.emit 'issue', issue
		return

	socket.on 'asapObj', (asapObj) ->
		console.log 'asapObj', asapObj
		current_time = moment().format('lll')
		issue = new Issue({
			issue : 'Needs Help',
			username: asapObj.username,
			displayName: asapObj.displayName,
			time: current_time,
			isComplete: false
			})
		issue.save()
		console.log 'issueDb', issue
		console.log 'issue saved'
		io.sockets.emit 'asapIssue', issue
		return

	socket.on 'isComplete', (completeObj) ->
		console.log 'compObj', completeObj
		Issue.findByIdAndUpdate(completeObj.issueId, {
			isComplete : completeObj.isComplete
			}, (err, id) ->
				if err res.send 'ERROR!' else 
					console.log 'Completed and Updated!'
					)
		return
	return

#student routing
app.get '/', (req, res) ->
	res.render 'login', {user: req.user}

app.get '/student', (req, res) ->
	res.render 'index', {user: req.user}

#teacher routing
app.get '/teacher', (req, res) ->
	res.render 'teacher'

app.post '/help-request', (req, res) ->

#get and listen to server
server.listen(app.get('port'), () ->
  console.log 'Express server listening on port ' + app.get('port'))