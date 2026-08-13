<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyEmergencyContact;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class EmergencyContactController extends Controller
{
    /**
     * Get all emergency contacts for the logged-in delivery boy
     *
     * GET /api/delivery_boy/emergency-contacts
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Get all emergency contacts
            $emergencyContacts = DeliveryBoyEmergencyContact::where('delivery_boy_id', $deliveryBoy->id)
                ->orderBy('created_at', 'desc')
                ->get();

            return CommonHelper::responseWithData($emergencyContacts, $emergencyContacts->count(), );

        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to retrieve emergency contacts: ' . $e->getMessage());
        }
    }

    /**
     * Add a new emergency contact
     *
     * POST /api/delivery_boy/emergency-contacts
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Validation
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'mobile_number' => 'required|string|max:15|regex:/^[0-9]+$/',
                'relation' => 'required|string|max:100',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Create emergency contact
            $emergencyContact = DeliveryBoyEmergencyContact::create([
                'delivery_boy_id' => $deliveryBoy->id,
                'name' => $request->name,
                'mobile_number' => $request->mobile_number,
                'relation' => $request->relation,
            ]);

            return CommonHelper::responseSuccess('Emergency contact added successfully.', $emergencyContact);

        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to add emergency contact: ' . $e->getMessage());
        }
    }

    /**
     * Get a specific emergency contact
     *
     * GET /api/delivery_boy/emergency-contacts/{id}
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Request $request, $id)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Find emergency contact
            $emergencyContact = DeliveryBoyEmergencyContact::where('id', $id)
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->first();

            if (!$emergencyContact) {
                return CommonHelper::responseError('Emergency contact not found!');
            }

            return CommonHelper::responseSuccess('Emergency contact retrieved successfully.', $emergencyContact);

        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to retrieve emergency contact: ' . $e->getMessage());
        }
    }

    /**
     * Update an emergency contact
     *
     * PUT/PATCH /api/delivery_boy/emergency-contacts/{id}
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, $id)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Find emergency contact
            $emergencyContact = DeliveryBoyEmergencyContact::where('id', $id)
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->first();

            if (!$emergencyContact) {
                return CommonHelper::responseError('Emergency contact not found!');
            }

            // Validation
            $validator = Validator::make($request->all(), [
                'name' => 'sometimes|required|string|max:255',
                'mobile_number' => 'sometimes|required|string|max:15|regex:/^[0-9]+$/',
                'relation' => 'sometimes|required|string|max:100',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Update fields
            if ($request->has('name')) {
                $emergencyContact->name = $request->name;
            }
            if ($request->has('mobile_number')) {
                $emergencyContact->mobile_number = $request->mobile_number;
            }
            if ($request->has('relation')) {
                $emergencyContact->relation = $request->relation;
            }

            $emergencyContact->save();

            return CommonHelper::responseSuccess('Emergency contact updated successfully.', $emergencyContact);

        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to update emergency contact: ' . $e->getMessage());
        }
    }

    /**
     * Delete an emergency contact
     *
     * DELETE /api/delivery_boy/emergency-contacts/{id}
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Request $request, $id)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Find emergency contact
            $emergencyContact = DeliveryBoyEmergencyContact::where('id', $id)
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->first();

            if (!$emergencyContact) {
                return CommonHelper::responseError('Emergency contact not found!');
            }

            // Delete
            $emergencyContact->delete();

            return CommonHelper::responseSuccess('Emergency contact deleted successfully.');

        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to delete emergency contact: ' . $e->getMessage());
        }
    }
}
