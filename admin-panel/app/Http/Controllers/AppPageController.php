<?php

namespace App\Http\Controllers;

use App\Models\AppPage;
use App\Helpers\CommonHelper;
use Illuminate\Http\Request;

class AppPageController extends Controller
{
    /**
     * Get a specific page by type (for sellers/users)
     */
    public function show($pageType)
    {
        $validTypes = ['terms', 'privacy', 'about', 'contact'];

        if (!in_array($pageType, $validTypes)) {
            return CommonHelper::responseError("Invalid page type.");
        }

        $page = AppPage::getByType($pageType);

        if (!$page) {
            return CommonHelper::responseError("Page not found.");
        }

        return response()->json([
            'status' => 1,
            'message' => 'Page fetched successfully',
            'data' => [
                'id' => $page->id,
                'page_type' => $page->page_type,
                'title' => $page->title,
                'content' => $page->content,
            ]
        ]);
    }

    /**
     * Get all active pages
     */
    public function index()
    {
        $pages = AppPage::getAllActive();

        return response()->json([
            'status' => 1,
            'message' => 'Pages fetched successfully',
            'data' => $pages->map(function ($page) {
                return [
                    'id' => $page->id,
                    'page_type' => $page->page_type,
                    'title' => $page->title,
                    'content' => $page->content,
                ];
            })
        ]);
    }

    /**
     * Get terms and conditions
     */
    public function terms()
    {
        return $this->show(AppPage::TYPE_TERMS);
    }

    /**
     * Get privacy policy
     */
    public function privacy()
    {
        return $this->show(AppPage::TYPE_PRIVACY);
    }

    /**
     * Get about us
     */
    public function about()
    {
        return $this->show(AppPage::TYPE_ABOUT);
    }
}
