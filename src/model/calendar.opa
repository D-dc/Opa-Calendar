//
// src/model/calendar.opa
// @date: 03/2013
// @author: Diel Caroes
//
//
//


client module Calendar{

  /*
    Calculate if it is a leapyear
  */
  client function bool isLeap(int year, int month){
    if(month == 2){
      if( mod(year, 4) == 0){
        if( mod(year, 100) == 0 && mod(year, 400)!=0){
          false
        }else{
          true
        }
      }else{
        false
      }
    }else{
      false
    }
  }

  /*
    Return the amount of days in a month
  */
  client function int month_days(Date.date d){
    list(int) month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    int monthNumber=Date.Month.to_int(Date.get_month(d));

    if(isLeap(Date.get_year(d), monthNumber)){
      29;
    }else{
      Option.get(List.get(monthNumber, month_days));
    } 
  }

  /*
    Go to the first day of this month
  */
  client  function toFirstOfMonth(Date.date cur){
    firstOfMonth = Date.advance_by_days(cur, -(Date.get_day(cur)-1));
    firstOfMonth = Date.round_to_day(firstOfMonth);
    firstOfMonth
  }

  /*
    Shift to first monday (could be previous month)
  */
  client  function toFirstMondayOfCurrentWeek(Date.date cur){
    firstMondayOfCurrentWeek = Date.move_to_weekday(cur, {backward}, {monday});
    firstMondayOfCurrentWeek
  }
  
}