// Load express module using `require` directive 
let express = require('express') 
let app = express() 

// Define request response in root URL (/) 
app.get('/', function (req, res) { 
res.send('Hello World') 
}) 

// Launch listening server on port 3000 
app.listen(3000, function () { 
console.log('app listening on port 3000') 
})
