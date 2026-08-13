@php
    $app_name = \App\Models\Setting::get_value('app_name');
    $currency = \App\Models\Setting::get_value('currency') ?? '$';
    $support_email = \App\Models\Setting::get_value('support_email');
    $support_number = \App\Models\Setting::get_value('support_number');
@endphp

@if(isset($customer) && isset($returnRequest))
    <p style="line-height: 24px; margin-bottom:15px;">
        Dear {{ $customer->name }},
    </p>

    <p style="line-height: 24px; margin-bottom: 15px;">
        Your return request #{{ $returnRequest->id }} for order #{{ $returnRequest->order_id }} has been <strong>{{ $status_name }}</strong>.
    </p>

    @if($returnRequest->status == \App\Models\ReturnStatusList::$rApproved)
        <p style="line-height: 24px; margin-bottom: 15px;">
            Your return request has been accepted and the refund amount has been credited to your wallet. 
            You can use this amount for future purchases on {{ $app_name }}.
        </p>
    @elseif($returnRequest->status == \App\Models\ReturnStatusList::$rRejected)
        <p style="line-height: 24px; margin-bottom: 15px;">
            We regret to inform you that your return request has been rejected. 
            If you have any questions or concerns, please contact our support team.
        </p>
    @elseif($returnRequest->status == \App\Models\ReturnStatusList::$rDeliveryBoyAssigned)
        <p style="line-height: 24px; margin-bottom: 15px;">
            A delivery boy has been assigned to collect your return. You will be contacted soon to arrange the pickup.
        </p>
    @elseif($returnRequest->status == \App\Models\ReturnStatusList::$rOutForPickup)
        <p style="line-height: 24px; margin-bottom: 15px;">
            Our delivery boy is on the way to collect your return. Please keep the items ready for pickup.
        </p>
    @elseif($returnRequest->status == \App\Models\ReturnStatusList::$rReceivedFromCustomer)
        <p style="line-height: 24px; margin-bottom: 15px;">
            We have received your return items. We are processing your refund and it will be credited to your wallet shortly.
        </p>
    @elseif($returnRequest->status == \App\Models\ReturnStatusList::$rCancelled)
        <p style="line-height: 24px; margin-bottom: 15px;">
            Your return request has been cancelled.
        </p>
    @elseif($returnRequest->status == \App\Models\ReturnStatusList::$rReturnToSeller)
        <p style="line-height: 24px; margin-bottom: 15px;">
            Your return items have been sent back to the seller. The refund process will be completed once the seller confirms receipt.
        </p>
    @endif

    <div style="background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
        <h3 style="color: #333; margin-bottom: 15px;">Return Request Details</h3>
        <table style="width: 100%; border-collapse: collapse;">
            <tr>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Return Request ID:</strong></td>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;">#{{ $returnRequest->id }}</td>
            </tr>
            <tr>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Order ID:</strong></td>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;">#{{ $returnRequest->order_id }}</td>
            </tr>
            <tr>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Status:</strong></td>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;">{{ $status_name }}</td>
            </tr>
            <tr>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Request Date:</strong></td>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;">{{ $returnRequest->created_at->format('M d, Y H:i') }}</td>
            </tr>
            @if($returnRequest->remarks)
            <tr>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Remarks:</strong></td>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;">{{ $returnRequest->remarks }}</td>
            </tr>
            @endif
        </table>
    </div>

    <p style="line-height: 24px; margin-bottom: 15px;">
        Thank you for choosing {{ $app_name }}!
    </p>

    <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
        <p style="font-size: 12px; color: #666; margin-bottom: 5px;">
            <strong>Support Information:</strong>
        </p>
        @if($support_email)
        <p style="font-size: 12px; color: #666; margin-bottom: 5px;">
            Email: {{ $support_email }}
        </p>
        @endif
        @if($support_number)
        <p style="font-size: 12px; color: #666; margin-bottom: 5px;">
            Phone: {{ $support_number }}
        </p>
        @endif
    </div>

@else
    <p style="line-height: 24px; margin-bottom:15px;">
        There was an error processing your return request notification.
    </p>
@endif
