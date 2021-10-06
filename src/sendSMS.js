var twilio = require('twilio');
const twilioNum = '+13231111111';
var accountSid = 'AC8fb6252f7d664e3cf1fd0e6d288b40a2'; // Your Account SID from www.twilio.com/console
var authToken = '8f4fef7bc87d46cc9edbae0b24764e16'; // Your Auth Token from www.twilio.com/console

var client = new twilio(accountSid, authToken);

// Require the fastify framework and instantiate it
const fastify = require('fastify')({
  logger: true
})
const url = require('url');

// itoolkit for PGM call option
const {
  Connection,
  ProgramCall,
  CommandCall
} = require('itoolkit');
const {
  parseString
} = require('xml2js');

// Declare a route
fastify.post('/send/:to', async (request, reply) => {
  const {
    params: {
      to
    }
  } = request;
  const queryObject = url.parse(request.raw.url, true).query;
  let msgbody = queryObject.body;
  await client.messages.create({
    body: msgbody, // SMS body
    to: to, // SMS to number
    from: '+13231111111' // SMS from a valid Twilio number
  }, function (err, message) {
    if (err) {
      console.error(err.message);
      reply.code(500)
        .header('Content-Type', 'application/json; charset=utf-8')
        .send({
          error: err.message
        });
    } else {
      reply.code(200)
        .header('Content-Type', 'application/json; charset=utf-8')
        .send({
          message: message
        });
    }
  });
})

// Run the server!
const start = async (port) => {
  try {
    await fastify.listen(port, '127.0.0.1');
    fastify.log.info(`server listening on ${fastify.server.address().port}`)
  } catch (err) {
    fastify.log.error(err)
    process.exit(1)
  }
}

const {
  DBPool
} = require('idb-pconnector');
const pool = new DBPool();

async function getFromSQL() {
  try {
    while (true) {
      let results = await pool.prepareExecute(
        'SELECT PHONE_NUM,MSG_BODY FROM TABLE(JESSEG.GETSMS2())');
      if (results == undefined) {
        console.log("nothing");
        continue;
      }
      for (var i in results.resultSet) {
        let to = results.resultSet[i].PHONE_NUM;
        let body = results.resultSet[i].MSG_BODY;
        sendSMS(to, '+13231111111', body);
      }
    }
  } catch (err) {
    console.log('error: ' + err.stack);
  }
}
async function getFromPgm() {
  try {
    const conn = new Connection({
      transport: 'idb',
    });
    const receiver = {
      name: 'receiver',
      type: 'ds',
      io: 'out',
      len: 'rec1',
      fields: [{
          name: 'phone_number',
          type: '21A',
          value: ''
        },
        {
          name: 'msg_body',
          type: '120A',
          value: ''
        },
      ],
    };
    const program = new ProgramCall('GETSMS', {
      lib: 'JESSEG'
    });
    program.addParam(receiver);
    conn.add(program);

    conn.run((error, xmlOutput) => {
      if (error) {
        throw error;
      }
      parseString(xmlOutput, (parseError, result) => {
        if (parseError) {
          throw parseError;
        }
        let to = result.myscript.pgm[0].parm[0].ds[0].data[0]._;
        let body = result.myscript.pgm[0].parm[0].ds[0].data[1]._;
        sendSMS(to, twilioNum, body);
      });
    });
  } catch (err) {
    console.log('error: ' + err.stack);
  }
}
async function getFromQ() {
  try {
    while (true) {
      let results =
        await pool.prepareExecute(`SELECT MESSAGE_DATA_UTF8 
                                       FROM TABLE(QSYS2.RECEIVE_DATA_QUEUE(
                                        DATA_QUEUE => 'SNDSMSQ', 
                                        WAIT_TIME => 1,
                                        DATA_QUEUE_LIBRARY => 'JESSEG'))`);
      if (results != undefined) {
        let data = JSON.parse(results.resultSet[0].MESSAGE_DATA_UTF8);
        sendSMS(data.to, data.from, data.body);
      }
    }
  } catch (err) {
    console.log('error: ' + err.stack);
  }
}

function sendSMS(to, from, body) {
  console.log("sending message to (" + to + ") with body [" + body + "]");
  client.messages.create({
    body: body, // SMS body
    to: to, // SMS to number
    from: from // SMS from a valid Twilio number
  }, function (err, message) {
    if (err) {
      console.error(err.message);
    }
  });
}

var myArgs = process.argv.slice(2);
if (myArgs[2] != undefined) {
  sendSMS(myArgs[0], myArgs[1], myArgs[2]);
  console.log("done");
} else if (myArgs[0] == "pgm") {
  getFromPgm();
} else if (myArgs[0] == "sql") {
  getFromSQL();
} else if (myArgs[0] != undefined) {
  let port = myArgs[0];
  console.log("serving REST API on port " + port);
  start(port);
} else {
  getFromQ();
}