#!/usr/bin/env bash

cat << EOF > index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>O.R.CA documentation</title>
  </head>
  <body>
    <main>
        <h1> O.R.CA versions </h1>
        <ul>
EOF

for FOLDER in $(ls -d */)
do
echo "          <ol> <a href=\"./${FOLDER%%/}/index.html\">${FOLDER%%/}</a> </ol>" >> index.html
done

cat << EOF >> index.html
        </ul>
    </main>
  </body>
</html>
EOF
