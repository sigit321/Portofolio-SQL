#StandardSQL
--Create a table
drop table if exists belajar.seller_approve;
create table belajar.seller_approve as
--Create a temporary table
with coba as
  (select * from (select distinct cast((seller_id) as int64) as seller_id,
      date,
      category__1,
      category__2,
      seller_name,
      seller_segment,
      row_number () over (partition by seller_id order by date desc) as row_num
      from belajar.seller_tag st
      where category__1 in ("Bags and Travel","Men's Shoes and Clothing","Sports Shoes and Clothing","Watches Sunglasses Jewellery","Women's Shoes and Clothing")
      and tag_status = "approve"
      group by seller_id,
      date,
      category__1,
      category__2,
      seller_name,
      seller_segment)
      where row_num = 1
),
--delimeter label name
ttd as (select ds, 
               seller_id, 
               concat(label_new,",",",",",") as label 
                from 
                  (select date as ds, 
                    case when label= '0' then null
                    else label 
                    end as label_new,
                    seller_id,
                    from belajar.seller_tag st
                    )
                    where label_new is not null
                    order by ds
),
--split label name to 4 column
spliter as (select seller_id,
                   ds,
                   label, 
                   split(label,",")[offset(0)] as label1,
                   split(label,",")[offset(1)] as label2,
                   split(label,",")[offset(2)] as label3,
                   split(label,",")[offset(3)] as label4
                      from(select 
                            ds,
                            cb.seller_id as seller_id,
                            label, 
                              from ttd
                              right join coba cb
                              on ttd.seller_id = cb.seller_id)
),

unique_value as (select ds,seller_id,label,
                 case 
                  when label1 like "Men%" then 1
                  when label1 like "" then 10
                  else 2
                  end as label1,
                 case
                  when label2 like "Men%" then 1
                  when label2 like "" then 10
                  else 2
                  end as label2,
                 case
                  when label3 like "Men%" then 1
                  when label3 like "" then 10
                  else 2
                  end as label3,
                 case
                  when label4 like "Men%" then 1
                  when label4 like "" then 10
                  else 2
                  end as label4                 
                    from spliter
),
--tag uniq number for filtering label name 
jumlah as  (select * 
            from
              (select ds, seller_id,
                      label,qc,
                      row_number() over (partition by seller_id order by ds desc) as r_n
              from
                    (select
                    ds,seller_id, trim(label,",,,,")
                      as label,
                      case when  label_uniq in (4,13,22,31,8,16,24,32) then "Pass"
                      else "Fail"
                      end as QC
                        from (select ds,
                                    seller_id,
                                    label,
                                    (label1+label2+label3+label4) as label_uniq
                                        from unique_value)))where r_n = 1 ),
--joining date as sting
tanggal as ( select * from
                (select cast(bd.date as string) as date1, 
                        cast(ll.ds as string) as 
                        date2, 
                        week
                        from 
                          belajar.date bd
                          inner join belajar.lazlook ll
                          on bd.date=ll.ds
                          group by date1,date2,week))
--select all metrics perf
select * from 
       (select cast(ll.ds as string) as ds,t.week as 
        week,
        month,
        quarter, 
        year, 
        js.seller_id as seller_id,
        replace(label,"0","-") as label,
        qc,category__2,
        seller_name,
        seller_segment,
        coalesce(sum (ipv_1d),0) as ipv,
        coalesce(sum (ipv_uv_1d),0) AS IPV_uv,
        coalesce(sum (byr_cnt_1d),0) AS BYR,
        coalesce(sum (mord_cnt_1d),0) AS MORD,
        coalesce(sum (order_cnt_1d),0) AS ORD,
        coalesce(sum (pay_itm_cnt_1d),0) AS PAY_ITM,
        coalesce(sum (pay_qty_1d),0) AS PAY_QTY,
        coalesce(sum (pay_gmv_1d),0) AS PAY_GMV,
        coalesce(sum (pay_gmv_local_1d),0) AS PAY_GMV_L,
        coalesce(sum (a2c_uv_1d),0) AS A2C_UV,
        coalesce(sum (a2c_qty_1d),0) AS A2C_QTY,
        coalesce(sum (a2c_pv_1d),0) AS A2C_PV  from belajar.lazlook ll
        right join jumlah js
          on js.seller_id=ll.seller_id
          right join belajar.date dtt
            on js.ds=dtt.date
              inner join coba cb
                on js.seller_id=cb.seller_id
                inner join tanggal t
                  on cast(ll.ds as string)=t.date2
        GROUP BY ll.ds,
                t.week,
                month,
                quarter, 
                year, 
                js.seller_id,
                label,qc,
                category__2,
                seller_name,
                seller_segment
                
      )
        where ds is not null
        order by ds asc
--)
