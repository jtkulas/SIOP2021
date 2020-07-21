* Encoding: UTF-8.
/* SPSS Macro for Multi-Level Weighting
/* Author: sedlo (www.mr-serv.com)

DATASET CLOSE ALL.
GET FILE = 'C:\Desktop\Fall 2018\FALL18FINALMerged.sav'.

/* EXAMPLE OF MACRO CALL:
/* !mac_weight
/*  N [1115]          /* [N] - number of cases after weighting; an optional parameter, may be omitted
/*  w_control [yes]   /* [w_control] - check tables in output after weigting (CTABLES required); if omitted then only min and max of weighting variable are computed
/*  w_var [weight]    /* [w_war] - MANDATORY PARAMETER - name of weighting variable; already an existed variable or not
/*  w_vars [          /* [w_wars] - MANDATORY PARAMETER - parameters for weighting in a group of 3 parameters in a row; each group contains following parameters: [variable] [category code] [category quota]
/*   q1 1 0.5         /* -> quota can be set in form of percent (without symbol %) or as the number of cases
/*   q1 2 0.5         /* -> macro converts quotas according to set proportions, (e.g. quotas for 2 categories are 0.40 and 0.10, then this is converted to 0.80 a 0.20)
/*   q2 1 0.25        /* -> you can set all parameters in one row, but entering each quota to a new row is clearer
/*   q2 2 0.4         /* -> entering quotas in this form is ok:                      w_vars [q1 1 328 q1 2 328 q2 1 0.25 q2 2 0.40 q2 3 0.35]
/*   q2 3 0.35        /* -> and exactly the same quotas can be entered in this form: w_vars [q1 1 0.5 q1 2 0.5 q2 1 2500 q2 2 4000 q2 3 3500]
/*  ]
/* .

/* you can enter an arbitraty number of weighting criteria
/* be careful to set quota for each category (e.g. there must be entered quotas for both male and female)
/* the weighting variable is computed iteratively, number of iterations is equal to the product of entered categories and number of weighting criteria (variables)
/* in each step weights are refined according to the first criterion, then the second criterion etc. - this is repeated as many times as specified weighting categories   
/* e.g. there are 2 categories for gender and 3 categories for age, then there are 2 criteria (variables gender and age) and 5 categories, number of iterations is 10
/* this number of iterations is totally sufficient
/* if the weights were not counted to correspond the quotas, other iterations would not help and it si necessary to adjust parameters for weighting
/* e.g. it can happen when 1000 interviews from Prague are required but there are only 5 such interviews in the data  


DEFINE !mac_weight (w_vars = !ENCLOSE('[',']') / w_var = !ENCLOSE('[',']') / N = !ENCLOSE('[',']')  / w_control = !ENCLOSE('[',']') )

/* setting initial variables

  weight off.
  compute !w_var = 1.
  variable label !w_var 'Weight'.
  aggregate
    /outfile=* mode=addvariables overwritevars=yes
    /@total 'Universum' = sum(!w_var).
  compute @real = 1.
  compute @q_real = 100 * @real / @total.
  execute.

/* adjusting the universe (i.e. required total weighted number of respondents)
/* it is either the actual or the required number of interviews

  !IF (!N~=!NULL) !THEN
     compute @total = !N.
  !IFEND


/* creating variables for entering weighting criteria

  !LET !w_num_param = !NULL
  !DO !w_pom !IN (!w_vars)
    !LET !w_num_param = !CONCAT(!w_num_param,"1")
  !DOEND

  !LET !hlp_vars = !w_vars
  !DO !w_hlp = 1 !TO !UNQUOTE(!LENGTH(!w_num_param)) !BY 3
    !LET !hlp_var    = !HEAD(!hlp_vars)
    !LET !hlp_vars   = !TAIL(!hlp_vars)
    !LET !hlp_code   = !HEAD(!hlp_vars)
    !LET !hlp_vars   = !TAIL(!hlp_vars)
    !LET !hlp_weight = !HEAD(!hlp_vars)
    !LET !hlp_vars   = !TAIL(!hlp_vars)
    recode !hlp_var (!hlp_code = !hlp_weight) into !CONCAT("@w",!hlp_var).
  !DOEND
  execute.


/* standardization: sum of quotas for a variable is equal to 1
/* it is multiplied by universe to obtain the desired number of respondents
/* creating help variables for check outputs to compare quotas and resulting weighted numbers

  !LET !hlp_vars = !w_vars
  !LET !w_hlp_crit  = !NULL
  !DO !w_hlp = 1 !TO !UNQUOTE(!LENGTH(!w_num_param)) !BY 3
    !LET !hlp_var  = !HEAD(!hlp_vars)
    !LET !hlp_vars = !TAIL(!TAIL(!TAIL(!hlp_vars)))
    !IF (!w_hlp_crit ~= !hlp_var) !THEN
      !LET !w_hlp_crit = !hlp_var
      compute !CONCAT("@ww",!w_hlp_crit) = !CONCAT("@w",!w_hlp_crit).
      compute !CONCAT("@www",!w_hlp_crit) = !CONCAT("@w",!w_hlp_crit).
      sort cases by !w_hlp_crit.
      if (!w_hlp_crit= lag(!w_hlp_crit)) !CONCAT("@ww",!w_hlp_crit) = lag(!CONCAT("@ww",!w_hlp_crit)).
      if (!w_hlp_crit= lag(!w_hlp_crit)) !CONCAT("@www",!w_hlp_crit) = lag(!CONCAT("@www",!w_hlp_crit)).
      if (!w_hlp_crit<>lag(!w_hlp_crit)) !CONCAT("@ww",!w_hlp_crit) = sum(lag(!CONCAT("@ww",!w_hlp_crit)),!CONCAT("@w",!w_hlp_crit)).
      if (!w_hlp_crit<>lag(!w_hlp_crit)) !CONCAT("@www",!w_hlp_crit) = sum(lag(!CONCAT("@www",!w_hlp_crit)),!CONCAT("@w",!w_hlp_crit)).
      aggregate
        /outfile=* mode=addvariables overwritevars=yes
        /!CONCAT("@ww",!w_hlp_crit) = max(!CONCAT("@ww",!w_hlp_crit))
        /!CONCAT("@www",!w_hlp_crit) = max(!CONCAT("@www",!w_hlp_crit)).
      compute !CONCAT("@ww",!w_hlp_crit) = @total * !CONCAT("@w",!w_hlp_crit) / !CONCAT("@ww",!w_hlp_crit).
      compute !CONCAT("@www",!w_hlp_crit) = !CONCAT("@w",!w_hlp_crit) / !CONCAT("@www",!w_hlp_crit).
      aggregate
        /outfile=* mode=addvariables overwritevars=yes
        /break = !w_hlp_crit
        /@number_of_resp = sum(!w_var).
      compute !CONCAT("@q_ww",!w_hlp_crit) = !CONCAT("@ww",!w_hlp_crit) / @number_of_resp.
      compute !CONCAT("@q_www",!w_hlp_crit) = 100 * !CONCAT("@www",!w_hlp_crit) / @number_of_resp.
    !IFEND
  !DOEND
  execute.


/* weighting
/* weighted number of cases in all categories for every criterion is calculated
/* it is compared with the quotas in all categories for every criterion
/* weighting variable is recalculated in order that the weighted number of cases match the quotas
/* whole operation is repeated as many times as the total number of entered categories

  !LET !w_hlp_crit  = !NULL
  !DO !w_hlp1 = 1 !TO !UNQUOTE(!LENGTH(!w_num_param)) !BY 3
    !LET !hlp_vars = !w_vars
    !DO !w_hlp2 = 1 !TO !UNQUOTE(!LENGTH(!w_num_param)) !BY 3
      !LET !hlp_var  = !HEAD(!hlp_vars)
      !LET !hlp_vars = !TAIL(!TAIL(!TAIL(!hlp_vars)))
      !IF (!w_hlp_crit ~= !hlp_var) !THEN
        !LET !w_hlp_crit = !hlp_var
        aggregate /outfile=* mode=addvariables overwritevars=yes
          /break = !w_hlp_crit
          /@number_of_resp = sum(!w_var).
        compute !w_var = !w_var * (!CONCAT("@ww",!w_hlp_crit) / @number_of_resp).
        execute.
      !IFEND
    !DOEND
  !DOEND


/* check - a table comparing quotas and weighted numbers
/* min and max of weights are computed - weights should be in the range (0.3;3) 

  !IF (!UPCASE(!w_control)="YES") !THEN
    compute @total = !N.
    !LET !hlp_vars = !w_vars
    !LET !w_hlp_crit  = !NULL
    !DO !w_hlp = 1 !TO !UNQUOTE(!LENGTH(!w_num_param)) !BY 3
      !LET !hlp_var  = !HEAD(!hlp_vars)
      !LET !hlp_vars = !TAIL(!TAIL(!TAIL(!hlp_vars)))
      !IF (!w_hlp_crit ~= !hlp_var) !THEN
        !LET !w_hlp_crit = !hlp_var
        compute !CONCAT("@q_",!w_var) = 100 * !w_var / @total.
        ctables
          /vlabels variables=@q_real !CONCAT("@q_www",!w_hlp_crit) !CONCAT("@q_",!w_var) @real !CONCAT("@q_ww",!w_hlp_crit) !w_var display=none
          /vlabels variables=!w_hlp_crit display=label
          /table 
               @q_real [s][sum '% (Real)' F40.2] +
               !CONCAT("@q_www",!w_hlp_crit) [s][sum '% (Quote)' F40.2] +
               !CONCAT("@q_",!w_var) [s][sum '% (Weighted)' F40.2] +
               @real [s][sum 'Number (Real)' F40.2] +
               !CONCAT("@q_ww",!w_hlp_crit) [s][sum 'Number (Quote)' F40.2] +
               !w_var [s][sum 'Number (Weighted)' F40.2] + 
               !w_var [s][minimum 'Min Weight' F40.2] + 
               !w_var [s][maximum 'Max Weight' F40.2]
               by !w_hlp_crit [c]
          /titles title = !QUOTE(!CONCAT("Checking of Weights - ",!w_hlp_crit))
          /slabels position=row
          /categories variables=!w_hlp_crit order=a key=value empty=include total=yes position=before.
      !IFEND
    !DOEND
  !ELSE
    descriptives weight /statistics = min max.
  !IFEND


/* deleting help variables

  !LET !w_hlp_crit  = !NULL
  !LET !hlp_vars = !w_vars
  !DO !w_hlp = 1 !TO !UNQUOTE(!LENGTH(!w_num_param)) !BY 3
    !LET !hlp_var  = !HEAD(!hlp_vars)
    !LET !hlp_vars = !TAIL(!TAIL(!TAIL(!hlp_vars)))
    !IF (!w_hlp_crit ~= !hlp_var) !THEN
      !LET !w_hlp_crit = !hlp_var
      delete variables !CONCAT("@w",!w_hlp_crit) !CONCAT("@ww",!w_hlp_crit) !CONCAT("@www",!w_hlp_crit) !CONCAT("@q_ww",!w_hlp_crit) !CONCAT("@q_www",!w_hlp_crit).
    !IFEND
  !DOEND
  delete variables @total @real @q_real @number_of_resp !CONCAT("@q_",!w_var).

  weight by !w_var.

!ENDDEFINE.

!mac_weight
 N [402]
 w_control [yes]
 w_var [weight]
 w_vars [
  SGENDER 1 0.4975
  SGENDER 2 0.5025
  AGE_RANGE 1 0.11994
  AGE_RANGE 2 0.33678
  AGE_RANGE 3 0.34661
  AGE_RANGE 4 0.19667
 ]
.

GET
  FILE=
DATASET NAME DataSet2 WINDOW=FRONT.
