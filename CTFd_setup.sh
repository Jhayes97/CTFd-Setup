#!/bin/sh
#Made for FCC Cyber
color() {       #This allows us to send progress messages in a nice color.
        ProgressTXT=$1
        echo -e '\E[37;44m'${ProgressTXT}'\033[0m'
}


color "Building dependencies"

apt-get update
apt-get upgrade
apt-get install openssh-server
apt-get install open-vm-tools
apt-get install nginx
apt-get install git
apt-get install curl
apt-get install gunicorn
apt-get install gzip
apt-get install mysql-server



color "Set Username and Password."
echo -e "Enter username:\n(Will be echoed)"
read usrname
echo Username:$usrname

function MatchPass()
{
echo -e "Enter Password:\n(Will not be echoed)"
read -s pass1
echo -e "Enter Password again:\n(Will not be echoed)"
read -s pass2
if [ "$pass1" == "$pass2" ]; then
        echo "Password confirmed"
        Passwd="$pass2"


else
        echo -e "[~]Passwords did not match. Try again.[~] \n"
        MatchPass
fi;
}
MatchPass
# echo "$Passwd"    # This is for debug purposes
        #There is now a variable named "$Passwd" and "$usrname" that can be used for setup


color "Updating pip"
	cd /home/user/Downloads
	curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
	python get-pip.py
	hash -r
	pip --version
color "Cloning ctfd github page"
	cd /home/user/
	git clone https://github.com/CTFd/CTFd.git
#take snapshot
color "Installing python virtualenv"
	pip install virtualenv
color "Creating virtual environment"
	cd /home/user/CTFd
	virtualenv ctfdenv
color "Checking for system dependencies"
	./prepare.sh
color "Activating virtual environment"
	source /home/user/CTFd/ctfdenv/bin/activate
color "Checking for dependencies...again"
	./prepare.sh
#test server is working, for debug purposes only
	#cd /home/user/CTFd/
	#gunicorn --bind 0.0.0.0:8000 -w 4 "CTFd:create_app()"
#take snapshot
color "Editing CTFd config.py file"
	cd /home/user/CTFd/CTFd
	cp config.py config.py.bak
	echo -e """import os

''' GENERATE SECRET KEY '''

if not os.getenv('SECRET_KEY'):
    # Attempt to read the secret from the secret file
    # This will fail if the secret has not been written
    try:
        with open('.ctfd_secret_key', 'rb') as secret:
            key = secret.read()
    except (OSError, IOError):
        key = None

    if not key:
        key = os.urandom(64)
        # Attempt to write the secret file
        # This will fail if the filesystem is read-only
        try:
            with open('.ctfd_secret_key', 'wb') as secret:
                secret.write(key)
                secret.flush()
        except (OSError, IOError):
            pass


''' SERVER SETTINGS '''


class Config(object):
    \"\"\"
    CTFd Configuration Object
    \"\"\"

    '''
    === REQUIRED SETTINGS ===

    SECRET_KEY:
        The secret value used to creation sessions and sign strings. This should be set to a random string. In the
        interest of ease, CTFd will automatically create a secret key file for you. If you wish to add this secret key
        to your instance you should hard code this value to a random static value.

        You can also remove .ctfd_secret_key from the .gitignore file and commit this file into whatever repository
        you are using.

        http://flask.pocoo.org/docs/latest/quickstart/#sessions

    DATABASE_URL:
        The URI that specifies the username, password, hostname, port, and database of the server
        used to hold the CTFd database.

        e.g. mysql+pymysql://root:<YOUR_PASSWORD_HERE>@localhost/ctfd

    CACHE_TYPE:
        Specifies how CTFd should cache configuration values. If CACHE_TYPE is set to 'redis', CTFd will make use
        of the REDIS_URL specified in environment variables. You can also choose to hardcode the REDIS_URL here.

        It is important that you specify some sort of cache as CTFd uses it to store values received from the database. If
        no cache is specified, CTFd will default to a simple per-worker cache. The simple cache cannot be effectively used
        with multiple workers.

    REDIS_URL is the URL to connect to a Redis server.
        e.g. redis://user:password@localhost:6379
        http://pythonhosted.org/Flask-Caching/#configuring-flask-caching
    '''
    SECRET_KEY = os.getenv('SECRET_KEY') or key
    DATABASE_URL = os.getenv('DATABASE_URL') or 'sqlite:///{}/ctfd.db'.format(os.path.dirname(os.path.abspath(__file__)))
    REDIS_URL = os.getenv('REDIS_URL')

    SQLALCHEMY_DATABASE_URI = DATABASE_URL
    CACHE_REDIS_URL = REDIS_URL
    if CACHE_REDIS_URL:
        CACHE_TYPE = 'redis'
    else:
        CACHE_TYPE = 'filesystem'
        CACHE_DIR = os.path.join(os.path.dirname(__file__), os.pardir, '.data', 'filesystem_cache')
        CACHE_THRESHOLD = 0  # Override the threshold of cached values on the filesystem. The default is 500. Don't change unless you know what you're doing.

    '''
    === SECURITY ===

    SESSION_COOKIE_HTTPONLY:
        Controls if cookies should be set with the HttpOnly flag.

    PERMANENT_SESSION_LIFETIME:
        The lifetime of a session. The default is 604800 seconds.

    TRUSTED_PROXIES:
        Defines a set of regular expressions used for finding a user's IP address if the CTFd instance
        is behind a proxy. If you are running a CTF and users are on the same network as you, you may choose to remove
        some proxies from the list.

        CTFd only uses IP addresses for cursory tracking purposes. It is ill-advised to do anything complicated based
        solely on IP addresses unless you know what you are doing.
    '''
    SESSION_COOKIE_HTTPONLY = (not os.getenv(\"SESSION_COOKIE_HTTPONLY\"))  # Defaults True
    SESSION_COOKIE_SAMESITE = os.getenv(\"SESSION_COOKIE_SAMESITE\") or 'Lax'
    PERMANENT_SESSION_LIFETIME = int(os.getenv(\"PERMANENT_SESSION_LIFETIME\") or 604800)  # 7 days in seconds
    TRUSTED_PROXIES = [
        r'^127\.0\.0\.1$',
        # Remove the following proxies if you do not trust the local network
        # For example if you are running a CTF on your laptop and the teams are
        # all on the same network
        r'^::1$',
        r'^fc00:',
        r'^10\.',
        r'^172\.(1[6-9]|2[0-9]|3[0-1])\.',
        r'^192\.168\.'
    ]

    '''
    === EMAIL ===

    MAILFROM_ADDR:
        The email address that emails are sent from if not overridden in the configuration panel.

    MAIL_SERVER:
        The mail server that emails are sent from if not overriden in the configuration panel.

    MAIL_PORT:
        The mail port that emails are sent from if not overriden in the configuration panel.

    MAIL_USEAUTH
        Whether or not to use username and password to authenticate to the SMTP server

    MAIL_USERNAME
        The username used to authenticate to the SMTP server if MAIL_USEAUTH is defined

    MAIL_PASSWORD
        The password used to authenticate to the SMTP server if MAIL_USEAUTH is defined

    MAIL_TLS
        Whether to connect to the SMTP server over TLS

    MAIL_SSL
        Whether to connect to the SMTP server over SSL

    MAILGUN_API_KEY
        Mailgun API key to send email over Mailgun

    MAILGUN_BASE_URL
        Mailgun base url to send email over Mailgun
    '''
    MAILFROM_ADDR = os.getenv(\"MAILFROM_ADDR\") or \"noreply@ctfd.io\"
    MAIL_SERVER = os.getenv(\"MAIL_SERVER\") or None
    MAIL_PORT = os.getenv(\"MAIL_PORT\")
    MAIL_USEAUTH = os.getenv(\"MAIL_USEAUTH\")
    MAIL_USERNAME = os.getenv(\"MAIL_USERNAME\")
    MAIL_PASSWORD = os.getenv(\"MAIL_PASSWORD\")
    MAIL_TLS = os.getenv(\"MAIL_TLS\") or False
    MAIL_SSL = os.getenv(\"MAIL_SSL\") or False
    MAILGUN_API_KEY = os.getenv(\"MAILGUN_API_KEY\")
    MAILGUN_BASE_URL = os.getenv(\"MAILGUN_BASE_URL\")

    '''
    === LOGS ===
    LOG_FOLDER:
        The location where logs are written. These are the logs for CTFd key submissions, registrations, and logins.
        The default location is the CTFd/logs folder.
    '''
    LOG_FOLDER = os.getenv('LOG_FOLDER') or os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs')

    '''
    === UPLOADS ===

    UPLOAD_PROVIDER:
        Specifies the service that CTFd should use to store files.

    UPLOAD_FOLDER:
        The location where files are uploaded. The default destination is the CTFd/uploads folder.

    AWS_ACCESS_KEY_ID:
        AWS access token used to authenticate to the S3 bucket.

    AWS_SECRET_ACCESS_KEY:
        AWS secret token used to authenticate to the S3 bucket.

    AWS_S3_BUCKET:
        The unique identifier for your S3 bucket.

    AWS_S3_ENDPOINT_URL:
        A URL pointing to a custom S3 implementation.

    '''
    UPLOAD_PROVIDER = os.getenv('UPLOAD_PROVIDER') or 'filesystem'
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER') or os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
    if UPLOAD_PROVIDER == 's3':
        AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
        AWS_S3_BUCKET = os.getenv('AWS_S3_BUCKET')
        AWS_S3_ENDPOINT_URL = os.getenv('AWS_S3_ENDPOINT_URL')

    '''
    === OPTIONAL ===

    REVERSE_PROXY:
        Specifies whether CTFd is behind a reverse proxy or not. Set to True if using a reverse proxy like nginx.
        You can also specify a comma seperated set of numbers specifying the reverse proxy configuration settings.

        See https://werkzeug.palletsprojects.com/en/0.15.x/middleware/proxy_fix/#werkzeug.middleware.proxy_fix.ProxyFix.
        For example to configure \`x_for=1, x_proto=1, x_host=1, x_port=1, x_prefix=1\` specify \`1,1,1,1,1\`.

        Alternatively if you specify \`true\` CTFd will default to the above behavior with all proxy settings set to 1.

    TEMPLATES_AUTO_RELOAD:
        Specifies whether Flask should check for modifications to templates and reload them automatically.

    SQLALCHEMY_TRACK_MODIFICATIONS:
        Automatically disabled to suppress warnings and save memory. You should only enable this if you need it.

    SWAGGER_UI:
        Enable the Swagger UI endpoint at /api/v1/

    UPDATE_CHECK:
        Specifies whether or not CTFd will check whether or not there is a new version of CTFd

    APPLICATION_ROOT:
        Specifies what path CTFd is mounted under. It can be used to run CTFd in a subdirectory.
        Example: /ctfd
    '''
    REVERSE_PROXY = os.getenv(\"REVERSE_PROXY\") or False
    TEMPLATES_AUTO_RELOAD = (not os.getenv(\"TEMPLATES_AUTO_RELOAD\"))  # Defaults True
    SQLALCHEMY_TRACK_MODIFICATIONS = os.getenv(\"SQLALCHEMY_TRACK_MODIFICATIONS\") is not None  # Defaults False
    SWAGGER_UI = '/' if os.getenv(\"SWAGGER_UI\") is not None else False  # Defaults False
    UPDATE_CHECK = (not os.getenv(\"UPDATE_CHECK\"))  # Defaults True
    APPLICATION_ROOT = os.getenv('APPLICATION_ROOT') or '/'

    '''
    === OAUTH ===

    MajorLeagueCyber Integration
        Register an event at https://majorleaguecyber.org/ and use the Client ID and Client Secret here
    '''
    OAUTH_CLIENT_ID = os.getenv(\"OAUTH_CLIENT_ID\")
    OAUTH_CLIENT_SECRET = os.getenv(\"OAUTH_CLIENT_SECRET\")


class TestingConfig(Config):
    SECRET_KEY = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' #note: we're not actually runnning our server with this secret key...
    PRESERVE_CONTEXT_ON_EXCEPTION = False
    TESTING = True
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://$usrname:$Passwd@localhost/CTFd'
    SERVER_NAME = 'localhost'
    UPDATE_CHECK = False
    REDIS_URL = None
    CACHE_TYPE = 'simple'
    CACHE_THRESHOLD = 500
    SAFE_MODE = True
""" > config.py


color "Creating service for reverse proxy"
	cd /etc/systemd/system/
	
	

echo -e """[Unit]
Description=Gunicorn instance to server ctfd
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=/home/user/CTFd
Environment=\"PATH=/home/user/CTFd/ctfdenv/bin\"
ExecStart=/home/user/CTFd/ctfdenv/bin/gunicorn --bind unix:ctfd.sock -w 4 -m 007 \"CTFd:create_app()\"

[Install]
WantedBy=multi-user.target""" > ctfd.service
	
	sudo chmod +077 ctfd.service

#create the service continued
	systemctl start ctfd.service
	systemctl enable ctfd.service
color "Creating the reverse proxy"
	cd /etc/nginx/sites-available
	cp default default.bak
	echo -e """server {
	listen 80;
	server_name 192.168.0.147;
	location / {
		include proxy_params;
		#proxy_pass http://127.0.0.1:8000;
		proxy_pass http://unix:/home/user/CTFd/ctfd.sock;
		}
	}""" > ctfd

	sudo ln -s /etc/nginx/sites-available/ctfd /etc/nginx/sites-enabled
	sudo cp ctfd default
	sudo nginx -t
	sudo systemctl restart nginx
color "This is where you would set up your theme. This section is commented out in the code, but if you want to use a theme instead of the default, just uncomment the lines and add the path directory to your theme."
	#cd /PATH/TO/YOUR/DIRECTORY
	#sudo cp -r /PATH/PATH/PATH/PATH/THEME /home/user/CTFd/CTFd/themes
	#systemctl restart nginx
color "Starting up the server; We're running!"
cd /home/user/CTFd/
    gunicorn --bind 0.0.0.0:8000 -w 4 "CTFd:create_app()"
