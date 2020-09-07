**free

// CRTRPGMOD MODULE(amra/sndmsg1) SRCSTMF('/sndmsg1.rpgle')
//   DBGVIEW(*ALL) INCDIR('/qibm/proddata/os/webservices/v1/client/include')
            
// CRTPGM PGM(amra/sndmsg1) BNDSRVPGM(QSYSDIR/QAXIS10CC)

// call amra/sndmsg1  PARM('phone' 'msg')

// --------------------------------------------------------------------
// Include files 
// --------------------------------------------------------------------

// Web service client prototypes and constants
/COPY /qibm/proddata/os/webservices/V1/client/include/Axis.rpgleinc

// --------------------------------------------------------------------
// External function prototypes 
// --------------------------------------------------------------------

dcl-pr printf int(10) ExtProc(*DclCase); 
   format     POINTER VALUE OPTIONS(*STRING);
   arg1       POINTER VALUE OPTIONS(*STRING:*NOPASS);
   arg2       POINTER VALUE OPTIONS(*STRING:*NOPASS);
end-pr;

dcl-pr system int(10) ExtProc(*DclCase); 
   cmd        POINTER VALUE OPTIONS(*STRING);
end-pr;

// --------------------------------------------------------------------
// Stand-alone variables and constants
// --------------------------------------------------------------------

DCL-S rc              INT(10);
DCL-S tHandle         POINTER;

DCL-S uri             CHAR(200);
DCL-S response        CHAR(32768);
DCL-S request         CHAR(32768);
DCL-S propBuf1        CHAR(100);
DCL-S propBuf2        CHAR(100);
DCL-S propInt         INT(10);

DCL-S NULLSTR         CHAR(1) INZ(X'00');
DCL-S NONE            CHAR(10);
DCL-C NEWLINE         X'25';

// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Web service logic. The code will attempt to invoke a Web service. 
// --------------------------------------------------------------------
// --------------------------------------------------------------------

Dcl-pr sndmsg1 ExtPgm;
 phone       char(11) const;
 message     char(20) const;
End-pr;

Dcl-Pi *N;
 phone       char(11) const;
 message     char(20) const;
End-pi; 

printf(NEWLINE + '------------------------' + NEWLINE);

// Turn on tracing. Delete existing file first.
system('rmvlnk ''/tmp/sndmsg1.log''');
axiscAxisStartTrace('/tmp/sndmsg1.log': *null);

uri = 'http://localhost/send/%2B'
       + %TRIM(phone) + '?body=' + %TRIM(message) +  X'00';

// Create HTTP transport handle.
tHandle = axiscTransportCreate(uri:AXISC_PROTOCOL_HTTP11);
if (tHandle = *NULL);
  printf ('TransportCreate() failed' + NEWLINE);
  return;
endif;

// Set HTTP method
propBuf1 = 'POST' + X'00';
rc = axiscTransportSetProperty(tHandle: AXISC_PROPERTY_HTTP_METHOD: %addr(propBuf1));
       
// Set connect timeout value
propInt = 30;
rc = axiscTransportSetProperty(tHandle: AXISC_PROPERTY_CONNECT_TIMEOUT: %addr(propInt));

// Set SSL information
NONE = 'NONE' + X'00';
propBuf1 = '/QIBM/USERDATA/ICSS/CERT/SERVER/DEFAULT.KDB' + X'00';
propBuf2 = 'true' + X'00';

rc = axiscTransportSetProperty(tHandle: AXISC_PROPERTY_HTTP_SSL:  
                               %addr(propBuf1):                  // keystore path
                               %addr(NULLSTR): %addr(NULLSTR):   // password, label - not used
                               %addr(NONE):%addr(NONE):          // turn off  SSLv1 and SSLv2
                               %addr(NULLSTR):%addr(NULLSTR): %addr(NULLSTR): // allow TLSv1,  TLSv1.1, TLSv1.2
                               %addr(propBuf2):  // allow soft errors,  e.g. certificate not in keystore
                               *NULL);
if (rc = -1);
   checkError('TransportSetProperty:  HTTP_SSL');
endif;

// Flush transport so request is sent and receive response.
rc = axiscTransportFlush(tHandle);
if (rc = -1);
  checkError ('TransportFlush()');
else;
  receiveData();
endif;


// Cleanup handle.
axiscTransportDestroy(tHandle);

*INLR = *ON;
RETURN;                                    

// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Procedure declarations 
// --------------------------------------------------------------------
// --------------------------------------------------------------------
        
       
// =========================================
// Handle error
// =========================================
DCL-PROC checkError ;
dcl-pi *n;
   msg varchar(5000) const;
end-pi;
  
DCL-S axisCode   INT(10);
DCL-S statusCode POINTER;
DCL-S rc         INT(10);

axisCode = axiscTransportGetLastErrorCode(tHandle);
printf (msg + ' call failed: ' + %CHAR(axisCode) + ':' + 
         %STR(axiscTransportGetLastError(tHandle)) + NEWLINE);

END-PROC checkError;
          
// =========================================
// Receive data
// =========================================
DCL-PROC receiveData ;
dcl-pi *n;
end-pi;       

DCL-S header     POINTER;
DCL-S property   CHAR(100);
DCL-S bytesRead  INT(10) inz(0);

clear response;
clear header;

rc = axiscTransportReceive(tHandle: %ADDR(response): %SIZE(response): 0);
dow rc > 0 AND bytesRead < %SIZE(response);
   bytesRead = bytesRead + rc;
   rc = axiscTransportReceive(tHandle: %ADDR(response)+bytesRead: %SIZE(response)-bytesRead: 0);
enddo;

if (rc = -1);
   checkError ('TransportReceive()');
else;
   if (bytesRead  > 0);
     printf ('RESPONSE (' + %CHAR(bytesRead) + ' bytes):' + NEWLINE+NEWLINE);
     printf (%trim(response) + NEWLINE+NEWLINE);
   endif;

   // Dump status code
   rc = axiscTransportGetProperty(tHandle: AXISC_PROPERTY_HTTP_STATUS_CODE: %addr(header));
   printf ('HTTP STATUS CODE: ' + %str(header) + NEWLINE);
endif;

END-PROC receiveData;                                                           
