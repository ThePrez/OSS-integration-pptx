**free
dcl-pi *n;
   parm likeds(parm_t);
end-pi;
dcl-ds parm_t qualified template;
   phone_number char(21);
   msg_body char(120);
end-ds;
parm.phone_number = '+15071111111';
parm.msg_body = 'Hello from RPG!';
return;















