PROJECT_DIRECTORY="$1"

# TODO: Pin apt-get packages to the same versions Heroku uses

# Install dependencies
echo "Updating apt repositories..."
apt-get update -qq

echo "Ensuring dependencies installed..."
apt-get --yes -qq install \
    make \
    git \
    build-essential \
    python-software-properties \
    postgresql-9.1 \
    postgresql-contrib-9.1 \
    libpq-dev \
    python-dev

# Configure Postgres
sudo -i -u postgres sh <<EOF
    psql \
        --quiet \
        --file=/home/vagrant/${PROJECT_DIRECTORY}/create_db.sql
EOF

cd $PROJECT_DIRECTORY

# Warn if Windows newlines are detected and try to fix the problem
if grep --quiet --binary --binary-files=without-match $(printf '\r') README.md; then
    echo
    cat development/scripts/crlf-warning.txt
    echo

    echo 'Running "git config core.autocrlf false"'
    git config core.autocrlf false

    exit 1
fi

# Set up the environment, the database, and run Gittip
test -f local.env || cp defaults.env local.env
make local.env env schema data

# Add run script
cd ..
cat > run <<EOF
#!/bin/sh
sudo pkill aspen
cd $PROJECT_DIRECTORY
make run
EOF
chmod +x run

# Output helper text
cat <<EOF

Gittip installed! To run,
$ vagrant ssh
$ ./run
EOF
