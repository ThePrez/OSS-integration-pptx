**free
// Don't call this program directly
// Use the SENDSMS command
dcl-pi *n;
   parm1 varchar(20);
   parm2 varchar(20);
   parm3 varchar(5000);
end-pi;

dcl-c QT ''''; // single quote
dcl-c NODEJS_DIR '/home/JGORZINS/projects/oss-integration-pptx+
                 /ibmi-oss-examples/nodejs/';
dcl-c TWILIO_DIR 'Send-SMS-with-Twilio-from-IBM-i';
dcl-c NODE_CMD '/QOpenSys/pkgs/bin/node';
dcl-c JS_SEND_DATA_FROM_QUEUE 'sendSMSDataFromQueue.js';
dcl-s cmd varchar(6000);
dcl-s qsh_cmd varchar(6100);

dcl-pr qcmdexc extpgm;
   cmd char(6100) const;
   cmdlen packed(15:5) const;
end-pr;

cmd = 'cd ' + NODEJS_DIR + TWILIO_DIR  // CD to the TWILIO directory
    + ' && ' + NODE_CMD + ' '          // Run the node command
    + JS_SEND_DATA_FROM_QUEUE          // JS script to run
    + ' "' + parm1 + '" '
    + ' "' + parm2 + '" '
    + ' "' + parm3 + '" ';
qsh_cmd = 'QSH CMD(' + QT + cmd + QT + ')';

QCMDEXC (qsh_cmd : %len(qsh_cmd));
return;
