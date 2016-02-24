class CartController < ApplicationController
	before_filter :authenticate_user!, :except => [:add_to_cart, :view_order]

  def add_to_cart
@product = Product.find(params[:product_id])

if @product.quantity < params[:quantity].to_i
redirect_to @product, notice: "Sorry, only #{@product.quantity} left in stock."


else
  	line_item = LineItem.new
  	line_item.product_id = params[:product_id].to_i
  	line_item.quantity = params[:quantity]

if user_signed_in?
line_item.customer_key = (current_user.id).to_s

else
  line_item.customer_key = remote_ip

end

  	line_item.save

  	line_item.line_item_total = line_item.quantity * line_item.product.price

  	line_item.save
  	redirect_to root_path
  end
    end

  def view_order

  	all_line_items = LineItem.all
@line_items = []
all_line_items.each do |line_item|
if user_signed_in?
  if (current_user.id).to_s == line_item.customer_key
    @line_items.push(line_item)

end
  end

if remote_ip == line_item.customer_key
  @line_items.push(line_item)
end

end
end
  def checkout
  	line_items = LineItem.all
  	@order = Order.new

  	sum = 0
  	line_items.each do |line_item|
  		sum+= line_item.line_item_total
    @order.order_items[line_item.product_id] = line_item.quantity
    line_item.product.quantity -= line_item.quantity
    line_item.product.save


  	end

  	@order.subtotal = sum
  	@order.sales_tax = sum * 0.07
  	@order.grand_total = sum + @order.sales_tax

  	@order.user_id = current_user.id

  
    @order.save

    LineItem.destroy_all


  end
def order_complete

@order = Order.find(params[:order_id])
  # this action is what actually performs the transaction.

    # Amount in cents
    @amount = (@order.grand_total.to_f.round(2) *100).to_i

    customer = Stripe::Customer.create(
      :email => current_user.email,
      :card => params[:stripeToken]
    )

    charge = Stripe::Charge.create(
      :customer => customer.id,
      :amount => @amount,
      :description => 'Rails Stripe customer',
      :currency => 'usd'
    )

    rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to charges_path

  
  end



end




