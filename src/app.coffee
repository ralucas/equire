# Module dependencies.
express = require 'express'
routes = require './../routes'
http = require 'http'
path = require 'path'
fs = require 'fs'
util = require 'util'
socketio = require 'socket.io'
mongoose = require 'mongoose'
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

#instantiate the Issue database
IssueSchema = new mongoose.Schema {
	issue: String,
	time: Object,
	displayName: {type: String, ref: 'User'}
}

Issue = mongoose.model 'Issue', IssueSchema

#instantiate the User database
UserSchema = new mongoose.Schema {
	openId: String,
	displayName: String,
	emails: [{value: String}],
}

UserSchema.plugin(findOrCreate);

User = mongoose.model 'User', UserSchema

#passport Google setup
passport.use new GoogleStrategy {
	returnURL: 'http://localhost:3000/auth/google/return',
	realm: 'http://localhost:3000'
	},
	(identifier, profile, done) ->
		User.findOrCreate {
			openId: identifier,
			displayName: profile.displayName,
			emails: [{value: profile.emails[0]['value']}]
		}, (err, user) ->
			done err, user

passport.serializeUser (user, done) ->
	done null, user

passport.deserializeUser (obj, done) ->
	done null, obj

#sockets on connection
io.sockets.on 'connection', (socket) ->
	console.log 'hello from your socket server'

	###
	on submission of issue, package into a new object
	that contains username, userID, issue, time, begin clock,
	category, then send it over to the teachers side
	###
	socket.on 'newIssue', (newIssue) ->
		console.log newIssue
		console.log 'socket', current_user
		issue = new Issue({
			issue: newIssue,
			time: new Date()
		})
		issue.save()
		console.log 'issue saved'
		return
	return

#student routing
app.get '/', (req, res) ->
	res.render 'login', {user: req.user}

app.get '/student', (req, res) ->
	current_user = req.user
	res.render 'index', {user: req.user}

app.get '/auth/google', passport.authenticate 'google'

app.get '/auth/google/return', passport.authenticate 'google', {
	session: true,
	successRedirect: '/student',
	failureRedirect: '/'}

#teacher routing
app.get '/teacher', (req, res) ->
	res.render 'teacher'

app.post '/help-request', (req, res) ->

#get and listen to server
server.listen(app.get('port'), () ->
  console.log 'Express server listening on port ' + app.get('port'))