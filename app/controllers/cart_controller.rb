class CartController < ApplicationController

	before_action :authenticate_user!, except: [:add_to_cart, :view_order]

  def add_to_cart

    if params[:quantity].blank?
      flash[:error] = "Select quantity!"
      redirect_to root_url
    else
    	line_item = LineItem.create(product_id: params[:product_id], quantity: params[:quantity])

    	line_item.update(line_item_total: (line_item.quantity * line_item.product.price))

    	redirect_back(fallback_location: root_path)
    end

  end

  def view_order
  	@line_items = LineItem.all
  end

  def delete_from_cart
  	line_item = LineItem.find(params[:line_item_id])

  	line_item.destroy

  	redirect_back(fallback_location: root_path)
  end

  def checkout

 	  line_items = LineItem.all

    if line_items.empty?
      redirect_to root_url
    else
  	  @order = Order.create(user_id: current_user.id, subtotal: 0)

  	  line_items.each do |line_item|
  	    line_item.product.update(quantity: (line_item.product.quantity - line_item.quantity))
  	    @order.order_items[line_item.product_id] = line_item.quantity 
  	    @order.subtotal += line_item.line_item_total
  	  end

  	  @order.save

  	  @order.update(sales_tax: (@order.subtotal * 0.08))
  	  @order.update(grand_total: (@order.sales_tax + @order.subtotal))

  	  line_items.destroy_all

    end
  end

  def order_complete
    @order = Order.find(params[:order_id])
    @amount = (@order.grand_total.to_f.round(2)*100).to_i

  customer = Stripe::Customer.create(
    :email => params[:stripeEmail],
    :source  => params[:stripeToken]
  )

  charge = Stripe::Charge.create(
    :customer    => customer.id,
    :amount      => @amount,
    :description => 'Fake customer',
    :currency    => 'usd'
  )

  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to root_path
  end

end
