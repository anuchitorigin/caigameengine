//################################# INCLUDE #################################
//---- System Modules ----
import express, { Router, Request, Response, NextFunction } from 'express';

//---- Application Modules ----
import K from '../engines/constant';
import { xString, xNumber, sendObj } from '../engines/originutil';
import { verify_user } from '../engines/authutil';
import { get_log_users, count_log_users } from '../engines/logfunc';

//################################# DECLARATION #################################
const THIS_FILENAME = 'log_user.ts';

//################################# FUNCTION #################################


//################################# ROUTE #################################
const router: Router = express.Router();

/* define the HOME route */
router.get('/', (req: Request, res: Response) => {
  res.send('This is -Log User- API endpoint.');
});

/* v----- all routes below this middleware will use Bearer Token -----v */
router.use(async (req: Request, res: Response, next: NextFunction) => {
  await verify_user(req, res, next);
});

/* define the Read-Filter route */
router.post('/filter', async (req: Request, res: Response) => {
  /**
   *  Request:-
   *    {
   *      limit: number,
   *      page: number, // 1,2,...
   *      sort: string, // "asc", "desc" ; default = ""
   *      datefrom: string, // start from (>=) '2022-06-06 16:00:00'
   *      dateto: string, // to but not include (<) '2022-06-07 16:00:00'
   *      userid: string, // for searching one user name
   *      incident: string,
   *      logdetail: string,
   *    }
   *  Response:-
   *    {
   *      status: 1,
   *      message: "ok",
   *      result: [
   *        {
   *          created: "2022-07-02T13:21:34.000Z", // NOTE: Depends on Time Zone of DB server
   *          userid: "anuchitb",
   *          incident: "credit:request",
   *          logdetail: "{ debtor_id: 1 }"
   *        },
   *        ...
   *      ]
   *    }
   */
  const limit = xNumber(req.body.limit); 
  const page = xNumber(req.body.page);
  const sort = xString(req.body.sort);
  const datefrom = xString(req.body.datefrom);
  const dateto = xString(req.body.dateto);
  const userid = xString(req.body.userid);
  const incident = xString(req.body.incident);
  const logdetail = xString(req.body.logdetail);
  if (!(limit && page)) {
    sendObj(3, 'Insufficient required fields', [], res);
    return;
  }
  if ((limit <= 0) || (page <= 0)) {
    sendObj(5, 'Incorrect pagination fields', [], res);
    return;
  }
  const log_users = await get_log_users(datefrom, dateto, userid, incident, logdetail, {
    limit: limit,
    page: page,
    sort: sort,
  });
  if (log_users == K.SYS_INTERNAL_PROCESS_ERROR) {
    sendObj(2, 'Internal process error', [], res);
    return;
  }
  sendObj(1, 'ok', log_users, res);
});

/* define the Read-Count route */
router.post('/count', async (req: Request, res: Response) => {
  /**
   *  Request:-
   *    {
   *      datefrom: string, // start from (>=) '2022-06-06 16:00:00'
   *      dateto: string, // to but not include (<) '2022-06-07 16:00:00'
   *      userid: string, // for searching one user name
   *      incident: string,
   *      logdetail: string,
   *    }
   *  Response:-
   *    {
   *      status: 1,
   *      message: "ok",
   *      result: [
   *        {
   *          RecordCount: 8
   *        }
   *      ]
   *    }
   */
  const datefrom = xString(req.body.datefrom);
  const dateto = xString(req.body.dateto);
  const userid = xString(req.body.userid);
  const incident = xString(req.body.incident);
  const logdetail = xString(req.body.logdetail);
  const RecordCount = await count_log_users(datefrom, dateto, userid, incident, logdetail);
  if (RecordCount == K.SYS_INTERNAL_PROCESS_ERROR) {
    sendObj(2, 'Internal process error', [], res);
    return;
  }
  sendObj(1, 'ok', [{ RecordCount: RecordCount }], res);
});

export default router;