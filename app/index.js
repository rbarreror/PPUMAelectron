const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const { finished } = require('stream');

// Global variables
var win;

const index = path.join('file://', __dirname, 'index.html');
const moduleSelector = path.join('file://', __dirname, 'sections', 'execute', 'moduleSelector.html');
const infile = path.join('file://', __dirname, 'sections', 'execute', 'infile.html');
const tagger = path.join('file://', __dirname, 'sections', 'execute', 'tagger.html');
const REname = path.join('file://', __dirname, 'sections', 'execute', 'REname.html');
const rowMerger = path.join('file://', __dirname, 'sections', 'execute', 'rowMerger.html');
const tableMerger = path.join('file://', __dirname, 'sections', 'execute', 'tableMerger.html');
const loader = path.join('file://', __dirname, 'sections', 'execute', 'loader.html');
const error = path.join('file://', __dirname, 'sections', 'execute', 'error.html');
const results = path.join('file://', __dirname, 'sections', 'execute', 'results.html');

var modToURL = {'Tagger': tagger, 'REname': REname, 'RowMerger': rowMerger, 'TableMerger': tableMerger, 'infile': infile};
var modToNum = {'Tagger': 1, 'REname': 2, 'RowMerger': 3, 'TableMerger': 4};

const jobsPath = path.join(__dirname, 'jobs');

// Functions to show different pages
function showMainPage () {

    win = new BrowserWindow({
        width: 780,
        height: 600,
        webPreferences: {
            nodeIntegration: true
        }
    })

    // No menu
    win.setMenu(null);
    
    // Load index.html
    win.loadURL(index);

    win.webContents.openDevTools();
}

// Start app
app.whenReady().then(showMainPage);

// Close app when all windows are closed
app.on('window-all-closed', () => {
    app.quit();
})

// Event Handling
ipcMain.on('select-modules', (e, workflow) => {
    // Send next window

    console.log(workflow);

    // Take next win from workflow object
    var nextWin = workflow.next > -1 ? workflow.modules[workflow.next] : "infile";
    var nextWinPath = modToURL[nextWin];
    
    // Show next window in renderer process
    var loadURL = win.loadURL(nextWinPath);
    
    // When web page is laoded, send workflow object
    loadURL.then((val) => {
        e.reply('send-workflow', workflow);
    });
    
})

ipcMain.on('run-workflow', (e, workflow) => {
    // Run workflow and send waiting page
    console.log(workflow);
    win.loadURL(loader);

    // Define workflow jobID
    workflow.jobID = makeid(10);
    workflowPath = path.join(jobsPath, workflow.jobID);

    // Create workflow folder
    fs.mkdirSync(workflowPath);

    // Create .ini files
    for (key in workflow.ini) {
        // Define ini path and write it
        iniPath = path.join(workflowPath, `${key}.ini`);
        fs.writeFileSync(iniPath, workflow.ini[key]);
    }
    
    // Define path to files uploaded by user
    infile_user = path.join(workflowPath, workflow.files.infile.name); // Define path where infile user can be found
    infile_feature_info = workflow.modules.includes('TableMerger') ? path.join(workflowPath, workflow.files.featInfo.name) : "" // If selected


    // Move input files to workflow folder
    fs.copyFileSync(workflow.files.infile.path, infile_user); // Main input
    
    if (infile_feature_info != "") fs.copyFileSync(workflow.files.featInfo.path, infile_feature_info); // Input for TableMerger

    if (Object.keys(workflow.files.regex).length > 0) {
        // if user sent regex.ini, use it
        fs.copyFileSync(workflow.files.regex.path, path.join(workflowPath, 'regex.ini'));

    } else {
        // if user did not send regex.ini, use default
        fs.copyFileSync(path.join(__dirname, 'PPUMA', 'config', 'configMod', 'regex.ini'), path.join(workflowPath, 'regex.ini'));
    }


    // Write workflow with numerical string
    var modulesString = ""; // Create numeric string
    for (i=0; i<workflow.modules.length; i++) modulesString += modToNum[workflow.modules[i]];

    // Run Bash script
    if (process.platform == 'linux') {
        // If linux...

        script = path.join(__dirname, 'PPUMA', 'integrator.sh');
        console.log(script);

        const bash = spawn('bash', [script, modulesString, infile_user, workflowPath, infile_feature_info]);

        bash.stdout.on('data', (data) => {
            console.log(`stdout: ${data}`);
        });

        bash.stderr.on(`data`, (data) => {
            console.error(`stderr: ${data}`);
        });

        bash.on('close', (code) => {
            console.log(`child process exited with code ${code}`);

            // Handle
            if (code == 0) {
                // If exit code is 0, workflow was executed successfully
                var loadURL = win.loadURL(results);

                loadURL.then((val) => {
                    // When URL is loaded, send jobID
                    e.reply('send-jobID', workflow);
                });

            } else {
                // Else, an error occurred
                win.loadURL(error);
            }
            
        });    
    } else {
        win.loadURL(index);
    }

})

ipcMain.on('see-results', (e, workflow) => {

    if (process.platform == 'linux') {
        // If linux OS
        var workflowPath = path.join(__dirname, 'jobs', workflow.jobID);

        const bash = spawn('xdg-open', [workflowPath]);

        bash.stdout.on('data', (data) => {
            console.log(`stdout: ${data}`);
        });

        bash.stderr.on(`data`, (data) => {
            console.error(`stderr: ${data}`);
        });

        bash.on('close', (code) => {
            console.log(`child process exited with code ${code}`);
        });

    } else {
        win.loadURL(index);
    }

});

// Local functions
function makeid(length) {
    var result = '';
    var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var charactersLength = characters.length;
    for ( var i = 0; i < length; i++ ) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
}



    // Create random code
    // Create ini files
    // Run bash script
    // Send result 

    // Handle user regex ini (assert format)
    // Move backward
    // Help page
    // GitHub
    // Tooltips