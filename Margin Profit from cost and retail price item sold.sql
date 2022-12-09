with total_sold as 
    (select id, 
     product_id, 
     sold_at 
     from thelook.inventory_items
       where sold_at is not null),

 sold_by_id as 
      (select id, 
        product_id,
        max(jo) as jo, 
        max(ji) as ji 
        from
              (select id, 
               product_id, 
               count(sold_at) over (partition by id,product_id) as jo, 
               count(sold_at) over (partition by product_id) as ji from total_sold
                order by id asc)
                group by id,product_id)

select sbi.product_id, 
       round((ji*cost),1) as total_cost, 
       round((ji*product_retail_price),1) as total_retail_price, 
       round(((ji*product_retail_price)-(ji*cost)),1) as margin_profit 
        from sold_by_id sbi
          inner join thelook.inventory_items ii
          on sbi.product_id = ii.product_id
        group by sbi.product_id,
        total_cost,
        product_retail_price, 
        total_retail_price, 
        margin_profit